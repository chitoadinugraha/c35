use axum::extract::ws::{Message, WebSocket};
use axum::http::HeaderMap;
use c35_ctx::{AppState, Ctx};
use c35_mod_chat::{
    chat_ensure, chat_title_from_text, prompt_followup_cancel_all_for_req, prompt_followup_cancel_rpc,
    prompt_followup_list, prompt_followup_publish_state, prompt_followup_put,
    prompt_followup_start_next_queued, prompt_run_cancel_children, prompt_run_cancel_request,
    prompt_run_enqueue, prompt_run_insert, prompt_run_row_new, prompt_turn, PromptTurnHooks,
};
use c35_mod_consumption::{consumption_list_rpc, consumption_put_rpc};
use c35_mod_expense::expense_put_rpc;
use c35_proto::{
    pb_decode, pb_encode, BillingPushBalance, BillingPushCommission, BillingPushQuota,
    PromptRunJob, ReqChannelDisconnect, ReqChannelWhatsappPairAbort, ReqChannelWhatsappPairStart,
    ReqChannelWhatsappPairWatch, ReqIdentityDelete,
    ReqPromptAbort, ResChannelWhatsappPair, ResChatStop, ResPromptDelta, ResPromptEnd, ResPromptFail,
    ResPromptStart, WsReq, WsRes, ws_req, ws_res,
};
use prost::Message as ProstMessage;
use c35_wire::WireErr;
use futures_util::StreamExt;
use tokio::sync::mpsc;
use tokio_util::sync::CancellationToken;

use crate::router::WsQuery;

struct PromptFlight {
    cancel: CancellationToken,
}

fn prompt_run_inline_forced() -> bool {
    std::env::var("C35_PROMPT_RUN_INLINE")
        .ok()
        .is_some_and(|v| v == "1" || v.eq_ignore_ascii_case("true"))
}

pub async fn handle(mut socket: WebSocket, state: AppState, q: WsQuery, headers: HeaderMap) {
    let geo_hint = c35_mod_identity::identity_geo_from_headers(&headers);
    let token = match q.jwt.as_deref() {
        Some(t) if !t.is_empty() => t,
        _ => {
            let _ = send_err(&mut socket, "", WireErr::Unauthorized).await;
            return;
        }
    };

    let caller_iid = match c35_mod_identity::auth_session_resolve(&state.pool, token).await {
        Ok(Some(i)) if i > 0 => i,
        _ => {
            let _ = send_err(&mut socket, "", WireErr::Unauthorized).await;
            return;
        }
    };

    let ctx = Ctx::from_state(&state, caller_iid);
    let (out_tx, mut out_rx) = mpsc::unbounded_channel::<WsRes>();
    let app_conn_id = c35_mod_device::remote_signaling_app_conn_register(out_tx.clone());
    let admin_session_id = crate::admin_fanout::admin_session_id();
    {
        let mut ev = c35_mod_event::EventCtx::for_owner(caller_iid, "c35-app");
        ev.conn_id = Some(admin_session_id as i64);
        let pool = state.pool.clone();
        let nats = state.nats.clone();
        tokio::spawn(async move {
            let _ = c35_mod_event::event_emit(
                &pool,
                nats.as_ref(),
                ev,
                c35_mod_event::kinds::USER_CONNECTED,
                serde_json::json!({}),
            )
            .await;
        });
    }
    let mut prompt_flight: Option<PromptFlight> = None;
    if let Some(nats) = state.nats.clone() {
        let fanout_tx = out_tx.clone();
        tokio::spawn(async move {
            billing_nats_fanout(nats, caller_iid, fanout_tx).await;
        });
    }
    if let Some(nats) = state.nats.clone() {
        let fanout_tx = out_tx.clone();
        let pool = state.pool.clone();
        tokio::spawn(async move {
            c35_mod_channel::channel_pair_nats_fanout(pool, nats, caller_iid, fanout_tx).await;
        });
    }

    loop {
        tokio::select! {
            Some(res) = out_rx.recv() => {
                if socket.send(Message::Binary(pb_encode(&res).into())).await.is_err() {
                    break;
                }
            }
            incoming = socket.next() => {
                match incoming {
                    Some(Ok(Message::Binary(data))) => {
                        let req: WsReq = match pb_decode(&data) {
                            Ok(r) => r,
                            Err(_) => {
                                let _ = send_err(&mut socket, "", WireErr::client("bad_request", "Invalid message")).await;
                                continue;
                            }
                        };
                        let req_id = req.req_id.clone();
                        match req.body {
                            Some(ws_req::Body::Prompt(p)) => {
                                prompt_req_put(&state, &ctx, &q, req_id, p, &out_tx, &mut prompt_flight);
                            }
                            Some(ws_req::Body::PromptAbort(ReqPromptAbort { chat_id, req_id: abort_req_id })) => {
                                if abort_req_id.is_empty() {
                                    prompt_abort(prompt_flight.as_ref());
                                } else {
                                    let pool = state.pool.clone();
                                    let rid = abort_req_id.clone();
                                    tokio::spawn(async move {
                                        let _ = prompt_run_cancel_request(&pool, &rid).await;
                                        let _ = prompt_run_cancel_children(&pool, &rid).await;
                                        let _ = prompt_followup_cancel_all_for_req(&pool, &rid).await;
                                    });
                                    prompt_abort(prompt_flight.as_ref());
                                }
                                let _ = out_tx.send(WsRes {
                                    req_id,
                                    body: Some(ws_res::Body::ChatStop(ResChatStop {
                                        chat_id,
                                        ai_reply_enabled: false,
                                    })),
                                });
                            }
                            _ => {
                                let res = dispatch(&state, &ctx, req, &q, &geo_hint, app_conn_id, admin_session_id, &out_tx).await;
                                if socket.send(Message::Binary(pb_encode(&res).into())).await.is_err() {
                                    break;
                                }
                                if matches!(res.body, Some(ws_res::Body::Err(_))) && req_id.is_empty() {
                                    break;
                                }
                            }
                        }
                    }
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(Message::Ping(p))) => { let _ = socket.send(Message::Pong(p)).await; }
                    Some(Ok(_)) => {}
                    Some(Err(_)) => break,
                }
            }
        }
    }

    c35_mod_device::remote_signaling_app_conn_unregister(app_conn_id);
    c35_mod_event::event_spawn(
        state.pool.clone(),
        state.nats.clone(),
        c35_mod_event::EventCtx::for_owner(caller_iid, "c35-app"),
        c35_mod_event::kinds::USER_DISCONNECTED,
        serde_json::json!({}),
    );
    crate::admin_fanout::admin_session_drop(admin_session_id).await;
}

fn prompt_abort(flight: Option<&PromptFlight>) {
    if let Some(f) = flight {
        f.cancel.cancel();
    }
}

fn prompt_fail(req_id: &str, message: String) -> WsRes {
    WsRes {
        req_id: req_id.into(),
        body: Some(ws_res::Body::PromptFail(ResPromptFail { message })),
    }
}

fn prompt_req_put(
    state: &AppState,
    ctx: &Ctx,
    q: &WsQuery,
    req_id: String,
    mut p: c35_proto::ReqPrompt,
    out_tx: &mpsc::UnboundedSender<WsRes>,
    prompt_flight: &mut Option<PromptFlight>,
) {
    let locale = q.locale.clone().unwrap_or_default();
    let title = chat_title_from_text(&p.text);
    let pool = state.pool.clone();
    let nats = state.nats.clone();
    let owner_iid = ctx.caller_iid;
    let out_tx = out_tx.clone();
    let req_id_spawn = req_id.clone();
    let cancel = CancellationToken::new();
    *prompt_flight = Some(PromptFlight { cancel: cancel.clone() });
    tokio::spawn(async move {
        let chat_id = match chat_ensure(&pool, owner_iid, p.chat_id, &title).await {
            Ok(id) => id,
            Err(e) => {
                let _ = out_tx.send(prompt_fail(&req_id_spawn, e.to_string()));
                return;
            }
        };
        p.chat_id = chat_id;
        let row = prompt_run_row_new(&req_id_spawn, owner_iid, chat_id, &p, &locale);
        if let Err(e) = prompt_run_insert(&pool, &row).await {
            let _ = out_tx.send(prompt_fail(&req_id_spawn, e.to_string()));
            return;
        }
        let _ = out_tx.send(WsRes {
            req_id: req_id_spawn.clone(),
            body: Some(ws_res::Body::PromptStart(ResPromptStart {
                chat_id,
                msg_id: 0,
                model: p.model.clone(),
            })),
        });
        if !prompt_run_inline_forced() {
            if let Some(nats_client) = nats.clone() {
                let job = PromptRunJob {
                    req_id: req_id_spawn.clone(),
                    owner_iid,
                    chat_id,
                };
                if prompt_run_enqueue(&nats_client, &job).await.is_ok() {
                    return;
                }
                tracing::warn!("[c35:prompt_run] JetStream enqueue failed, falling back to inline turn");
            }
        }
        match prompt_turn(
            &pool,
            nats.as_ref(),
            owner_iid,
            &req_id_spawn,
            p,
            &locale,
            |thought, d| {
                let _ = out_tx.send(WsRes {
                    req_id: req_id_spawn.clone(),
                    body: Some(ws_res::Body::PromptDelta(ResPromptDelta {
                        text: d,
                        thought,
                        blocks_json: String::new(),
                    })),
                });
            },
            |blocks_json| {
                let _ = out_tx.send(WsRes {
                    req_id: req_id_spawn.clone(),
                    body: Some(ws_res::Body::PromptDelta(ResPromptDelta {
                        text: String::new(),
                        thought: false,
                        blocks_json,
                    })),
                });
            },
            &cancel,
            PromptTurnHooks::default(),
        )
        .await
        {
            Ok(turn) => {
                let _ = out_tx.send(WsRes {
                    req_id: req_id_spawn.clone(),
                    body: Some(ws_res::Body::PromptEnd(ResPromptEnd {
                        msg_id: turn.assistant_msg_id,
                        tokens_in: turn.tokens_in,
                        tokens_out: turn.tokens_out,
                        cost_usd: turn.cost_usd,
                        duration_ms: turn.duration_ms,
                        model: turn.model,
                        req_id: req_id_spawn.clone(),
                        trace_json: String::new(),
                        error_message: turn.error_text,
                    })),
                });
                c35_mod_billing::billing_notify_owner(&pool, nats.as_ref(), owner_iid, Some(&out_tx)).await;
                if let Some(nats_client) = nats.as_ref() {
                    let _ = prompt_followup_start_next_queued(&pool, nats_client, &req_id_spawn).await;
                }
            }
            Err(e) => {
                let _ = out_tx.send(prompt_fail(&req_id_spawn, e.to_string()));
            }
        }
    });
}

async fn dispatch(
    state: &AppState,
    ctx: &Ctx,
    req: WsReq,
    q: &WsQuery,
    geo_hint: &c35_mod_identity::GeoHint,
    app_conn_id: u64,
    admin_session_id: u64,
    out_tx: &mpsc::UnboundedSender<WsRes>,
) -> WsRes {
    let req_id = req.req_id;
    match req.body {
        Some(ws_req::Body::SessionInit(init)) => match session_init(ctx, init, q, geo_hint).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::SessionInit(body)),
            },
            Err(e) => err_res(req_id, e),
        },
        Some(ws_req::Body::Invoke(mut inv)) => {
            inv.caller_iid = ctx.caller_iid;
            WsRes {
                req_id,
                body: Some(ws_res::Body::Invoke(
                    c35_wire_http::dispatch_invoke(state, inv).await,
                )),
            }
        }
        Some(ws_req::Body::ConsumptionList(r)) => {
            let locale = q.locale.as_deref().unwrap_or("en");
            WsRes {
                req_id,
                body: Some(ws_res::Body::ConsumptionList(
                    consumption_list_rpc(&state.pool, ctx.caller_iid, locale, r).await,
                )),
            }
        }
        Some(ws_req::Body::ConsumptionPut(r)) => {
            let locale = q.locale.as_deref().unwrap_or("en");
            match consumption_put_rpc(&state.pool, state.nats.as_ref(), ctx.caller_iid, locale, r).await {
                Ok(res) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::ConsumptionPut(res)),
                },
                Err(e) => err_res(req_id, WireErr::client("consumption_put_failed", e)),
            }
        }
        Some(ws_req::Body::ExpensePut(r)) => {
            let locale = q.locale.as_deref().unwrap_or("id");
            match expense_put_rpc(&state.pool, ctx.caller_iid, locale, r).await {
                Ok(res) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::ExpensePut(res)),
                },
                Err(e) => err_res(req_id, WireErr::client("expense_put_failed", e)),
            }
        }
        Some(ws_req::Body::InboxList(r)) => match c35_mod_chat::inbox_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::InboxList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("inbox_list_failed", e.to_string())),
        },
        Some(ws_req::Body::ChatMsgList(r)) => match c35_mod_chat::chat_msg_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::ChatMsgList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("chat_msg_list_failed", e.to_string())),
        },
        Some(ws_req::Body::ChatPatch(r)) => match c35_mod_chat::chat_patch(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::ChatPatch(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("chat_patch_failed", e.to_string())),
        },
        Some(ws_req::Body::ChatHistoryClear(r)) => match c35_mod_chat::chat_history_clear(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::ChatHistoryClear(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("chat_history_clear_failed", e.to_string())),
        },
        Some(ws_req::Body::AssetTagList(r)) => match c35_mod_chat::asset_tag_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::AssetTagList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("asset_tag_list_failed", e.to_string())),
        },
        Some(ws_req::Body::BotPeerList(r)) => match c35_mod_chat::bot_peer_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::BotPeerList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("bot_peer_list_failed", e.to_string())),
        },
        Some(ws_req::Body::ChatStop(r)) => match c35_mod_chat::chat_stop(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::ChatStop(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("chat_stop_failed", e.to_string())),
        },
        Some(ws_req::Body::ChatSend(r)) => match c35_mod_chat::chat_send(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::ChatSend(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("chat_send_failed", e.to_string())),
        },
        Some(ws_req::Body::PromptFollowupPut(r)) => {
            let chat_id = r.chat_id;
            match prompt_followup_put(
                &state.pool,
                ctx.caller_iid,
                chat_id,
                &r.req_id,
                &r.text,
                &r.attachments_json,
                r.kind,
                "app",
                None,
            )
            .await
            {
                Ok(body) => {
                    if !body.rejected {
                        let rid = if body.req_id.is_empty() { r.req_id.clone() } else { body.req_id.clone() };
                        let _ = prompt_followup_publish_state(
                            &state.pool,
                            state.nats.as_ref(),
                            ctx.caller_iid,
                            chat_id,
                            &rid,
                        )
                        .await;
                    }
                    WsRes {
                        req_id,
                        body: Some(ws_res::Body::PromptFollowupPut(body)),
                    }
                }
                Err(e) => err_res(req_id, WireErr::client("prompt_followup_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::PromptFollowupList(r)) => match prompt_followup_list(&state.pool, r.chat_id, &r.req_id).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::PromptFollowupList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("prompt_followup_list_failed", e.to_string())),
        },
        Some(ws_req::Body::PromptFollowupCancel(r)) => match prompt_followup_cancel_rpc(&state.pool, ctx.caller_iid, &r.id).await {
            Ok((body, notify)) => {
                if body.ok {
                    if let Some((chat_id, rid)) = notify {
                        let _ = prompt_followup_publish_state(
                            &state.pool,
                            state.nats.as_ref(),
                            ctx.caller_iid,
                            chat_id,
                            &rid,
                        )
                        .await;
                    }
                }
                WsRes {
                    req_id,
                    body: Some(ws_res::Body::PromptFollowupCancel(body)),
                }
            }
            Err(e) => err_res(req_id, WireErr::client("prompt_followup_cancel_failed", e.to_string())),
        },
        Some(ws_req::Body::LogList(r)) => match c35_mod_chat::log_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::LogList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("log_list_failed", e.to_string())),
        },
        Some(ws_req::Body::IdentityList(r)) => match c35_mod_identity::identity_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::IdentityList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("identity_list_failed", e.to_string())),
        },
        Some(ws_req::Body::IdentityGrantPatch(r)) => {
            match c35_mod_identity::identity_grant_patch(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::IdentityGrantPatch(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("identity_grant_patch_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::IdentityPut(r)) => {
            match c35_mod_identity::identity_put(
                &state.pool,
                state.nats.as_ref(),
                ctx.caller_iid,
                &req_id,
                r,
            )
            .await
            {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::IdentityPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("identity_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::ChannelWhatsappPairStart(r)) => pair_start_res(state, ctx, req_id, r).await,
        Some(ws_req::Body::ChannelWhatsappPairWatch(r)) => pair_watch_res(ctx, req_id, r).await,
        Some(ws_req::Body::ChannelWhatsappPairAbort(r)) => pair_abort_res(state, ctx, req_id, r).await,
        Some(ws_req::Body::ChannelDisconnect(r)) => channel_disconnect_res(state, ctx, req_id, r).await,
        Some(ws_req::Body::IdentityDelete(r)) => identity_delete_res(state, ctx, req_id, r).await,
        Some(ws_req::Body::SkillList(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::SkillList(
                c35_mod_skill::skill_list_rpc(&state.pool, ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::SkillPut(r)) => match c35_mod_skill::skill_put_rpc(&state.pool, ctx.caller_iid, r).await {
            Ok(res) => WsRes {
                req_id,
                body: Some(ws_res::Body::SkillPut(res)),
            },
            Err(e) => err_res(req_id, WireErr::client("skill_put_failed", e)),
        },
        Some(ws_req::Body::SkillCatalogList(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::SkillCatalogList(
                c35_mod_skill::skill_catalog_list_rpc(&state.pool, ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::SkillCatalogInstall(r)) => {
            match c35_mod_skill::skill_catalog_install_rpc(&state.pool, ctx.caller_iid, r).await {
                Ok(res) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SkillCatalogInstall(res)),
                },
                Err(e) => err_res(req_id, WireErr::client("skill_catalog_install_failed", e)),
            }
        }
        Some(ws_req::Body::SiteList(r)) => match c35_mod_site::site_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::SiteList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("site_list_failed", e.to_string())),
        },
        Some(ws_req::Body::TxList(r)) => match c35_mod_tx::tx_list(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::TxList(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("tx_list_failed", e.to_string())),
        },
        Some(ws_req::Body::SiteDraftGet(r)) => {
            match c35_mod_site::site_draft_get(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteDraftGet(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_draft_get_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteDraftPut(r)) => {
            match c35_mod_site::site_draft_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteDraftPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_draft_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SitePublish(r)) => {
            match c35_mod_site::site_publish(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SitePublish(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_publish_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteProductList(r)) => {
            match c35_mod_site::site_product_list(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteProductList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_product_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteProductPut(r)) => {
            match c35_mod_site::site_product_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteProductPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_product_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteContactList(r)) => {
            match c35_mod_site::site_contact_list(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteContactList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_contact_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteContactPut(r)) => {
            match c35_mod_site::site_contact_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteContactPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_contact_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteObjectList(r)) => {
            match c35_mod_site::site_object_list(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteObjectList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_object_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteObjectPut(r)) => {
            match c35_mod_site::site_object_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteObjectPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_object_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteDomainList(r)) => {
            match c35_mod_site::site_domain_list(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteDomainList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_domain_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteDomainPut(r)) => {
            match c35_mod_site::site_domain_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteDomainPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_domain_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteDomainVerify(r)) => {
            match c35_mod_site::site_domain_verify(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteDomainVerify(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_domain_verify_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::CollectionDefList(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::CollectionDefList(
                c35_mod_site::collection_def_list_rpc(&state.pool, ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::Sync(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::Sync(
                c35_mod_site::sync_pull(&state.pool, ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::RemoteIceConfig(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::RemoteIceConfig(
                c35_mod_device::remote_ice_config(ctx.caller_iid, r),
            )),
        },
        Some(ws_req::Body::RemoteSessionStart(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::RemoteSessionStart(
                c35_mod_device::remote_session_start(
                    &state.pool,
                    state.nats.as_ref(),
                    ctx.caller_iid,
                    app_conn_id,
                    out_tx,
                    r,
                )
                .await,
            )),
        },
        Some(ws_req::Body::RemoteSessionStop(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::RemoteSessionStop(
                c35_mod_device::remote_session_stop(
                    &state.pool,
                    state.nats.as_ref(),
                    ctx.caller_iid,
                    r,
                )
                .await,
            )),
        },
        Some(ws_req::Body::RtcSignalOffer(r)) => {
            match c35_mod_device::rtc_signal_offer_from_app(state.nats.as_ref(), ctx.caller_iid, r).await {
                Ok(()) => WsRes { req_id, body: None },
                Err(e) => err_res(req_id, WireErr::client("rtc_signal_offer_failed", e)),
            }
        }
        Some(ws_req::Body::RtcSignalAnswer(r)) => {
            match c35_mod_device::rtc_signal_answer_from_app(state.nats.as_ref(), ctx.caller_iid, r).await {
                Ok(()) => WsRes { req_id, body: None },
                Err(e) => err_res(req_id, WireErr::client("rtc_signal_answer_failed", e)),
            }
        }
        Some(ws_req::Body::RtcSignalIce(r)) => {
            match c35_mod_device::rtc_signal_ice_from_app(state.nats.as_ref(), ctx.caller_iid, r).await {
                Ok(()) => WsRes { req_id, body: None },
                Err(e) => err_res(req_id, WireErr::client("rtc_signal_ice_failed", e)),
            }
        },
        Some(ws_req::Body::MentionList(_)) => {
            let list = c35_mod_chat::mention_list_rpc(&state.pool, ctx.caller_iid).await;
            WsRes {
                req_id,
                body: Some(ws_res::Body::MentionList(list)),
            }
        }
        Some(ws_req::Body::MentionSearch(r)) => {
            let search = c35_mod_chat::mention_search_rpc(&state.pool, ctx.caller_iid, r).await;
            WsRes {
                req_id,
                body: Some(ws_res::Body::MentionSearch(search)),
            }
        }
        Some(ws_req::Body::SkillCatalogSearch(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::SkillCatalogSearch(
                c35_mod_skill::skill_catalog_search_rpc(&state.pool, ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::SkillCatalogSubmit(r)) => {
            match c35_mod_skill::skill_catalog_submit_rpc(&state.pool, ctx.caller_iid, r).await {
                Ok(res) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SkillCatalogSubmit(res)),
                },
                Err(e) => err_res(req_id, WireErr::client("skill_catalog_submit_failed", e)),
            }
        }
        Some(ws_req::Body::SkillRunReport(r)) => {
            match c35_mod_skill::skill_run_report_rpc(&state.pool, ctx.caller_iid, r).await {
                Ok(res) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SkillRunReport(res)),
                },
                Err(e) => err_res(req_id, WireErr::client("skill_run_report_failed", e)),
            }
        }
        Some(ws_req::Body::VoiceStt(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::VoiceStt(
                c35_mod_voice::voice_stt_rpc(&state.pool, state.nats.as_ref(), ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::VoiceTts(r)) => WsRes {
            req_id,
            body: Some(ws_res::Body::VoiceTts(
                c35_mod_voice::voice_tts_rpc(&state.pool, state.nats.as_ref(), ctx.caller_iid, r).await,
            )),
        },
        Some(ws_req::Body::StatsSubscribe(_)) => {
            match crate::admin_fanout::admin_stats_subscribe(
                &state.pool,
                state.nats.as_ref(),
                ctx.caller_iid,
                admin_session_id,
                out_tx.clone(),
            )
            .await
            {
                Ok(()) => WsRes { req_id, body: None },
                Err(e) => err_res(req_id, WireErr::client("stats_subscribe_failed", e.message)),
            }
        }
        Some(ws_req::Body::StatsUnsubscribe(_)) => {
            crate::admin_fanout::admin_stats_unsubscribe(admin_session_id).await;
            WsRes { req_id, body: None }
        }
        Some(ws_req::Body::LogSubscribe(r)) => {
            match crate::admin_fanout::admin_log_subscribe(
                &state.pool,
                state.nats.as_ref(),
                ctx.caller_iid,
                admin_session_id,
                r.owner_iid,
                out_tx.clone(),
            )
            .await
            {
                Ok(()) => WsRes { req_id, body: None },
                Err(e) => err_res(req_id, WireErr::client("log_subscribe_failed", e.message)),
            }
        }
        Some(ws_req::Body::LogUnsubscribe(_)) => {
            crate::admin_fanout::admin_log_unsubscribe(admin_session_id).await;
            WsRes { req_id, body: None }
        }
        Some(ws_req::Body::SiteConfigPut(r)) => {
            match c35_mod_site::site_config_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteConfigPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_config_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SitePreviewToken(r)) => {
            match c35_mod_site::site_preview_token(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SitePreviewToken(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_preview_token_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::TxGet(r)) => match c35_mod_tx::tx_get(&state.pool, ctx.caller_iid, r).await {
            Ok(body) => WsRes {
                req_id,
                body: Some(ws_res::Body::TxGet(body)),
            },
            Err(e) => err_res(req_id, WireErr::client("tx_get_failed", e.to_string())),
        },
        Some(ws_req::Body::TxPut(r)) => {
            match c35_mod_tx::tx_put(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::TxPut(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("tx_put_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::TxPreview(r)) => {
            match c35_mod_tx::tx_preview(&state.pool, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::TxPreview(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("tx_preview_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::TxDebtPay(r)) => {
            match c35_mod_tx::tx_debt_pay(&state.pool, ctx.caller_iid, r, Some(out_tx)).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::TxDebtPay(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("tx_debt_pay_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::SiteQueryRun(r)) => {
            match c35_mod_site::site_query_run(
                &state.pool,
                ctx.caller_iid,
                r.site_iids,
                &r.query_id,
                &r.params_json,
            )
            .await
            {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::SiteQueryRun(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("site_query_run_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::HintTouch(r)) => {
            match c35_mod_hint::hint_touch(&state.pool, ctx.caller_iid, r.asset_iid, &r.asset_kind).await {
                Ok(()) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::HintTouch(c35_proto::ResHintTouch { ok: true })),
                },
                Err(e) => err_res(req_id, WireErr::client("hint_touch_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailList(r)) => {
            match c35_mod_mail::mail_list_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailGet(r)) => {
            match c35_mod_mail::mail_get_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailGet(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_get_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailSend(r)) => {
            match c35_mod_mail::mail_send_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailSend(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_send_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMailboxList(r)) => {
            match c35_mod_mail::mail_mailbox_list_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailMailboxList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_mailbox_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailDomainList(r)) => {
            match c35_mod_mail::mail_domain_list_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailDomainList(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_domain_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailDomainAdd(r)) => {
            match c35_mod_mail::mail_domain_add_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes {
                    req_id,
                    body: Some(ws_res::Body::MailDomainAdd(body)),
                },
                Err(e) => err_res(req_id, WireErr::client("mail_domain_add_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailAccountGet(r)) => {
            match c35_mod_mail::mail_account_get_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailAccountGet(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_account_get_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailArchive(r)) => {
            match c35_mod_mail::mail_archive_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailArchive(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_archive_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMarkRead(r)) => {
            match c35_mod_mail::mail_mark_read_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailMarkRead(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_mark_read_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailGroupList(r)) => {
            match c35_mod_mail::mail_group_list_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailGroupList(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_group_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailGroupUpsert(r)) => {
            match c35_mod_mail::mail_group_upsert_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailGroupUpsert(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_group_upsert_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailGroupDelete(r)) => {
            match c35_mod_mail::mail_group_delete_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailGroupDelete(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_group_delete_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailBroadcast(r)) => {
            match c35_mod_mail::mail_broadcast_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailBroadcast(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_broadcast_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMailboxAdminList(r)) => {
            match c35_mod_mail::mail_mailbox_admin_list_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailMailboxAdminList(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_mailbox_admin_list_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMailboxCreate(r)) => {
            match c35_mod_mail::mail_mailbox_create_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailMailboxCreate(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_mailbox_create_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMailboxUpdate(r)) => {
            match c35_mod_mail::mail_mailbox_update_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailMailboxUpdate(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_mailbox_update_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailMailboxDelete(r)) => {
            match c35_mod_mail::mail_mailbox_delete_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailMailboxDelete(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_mailbox_delete_failed", e.to_string())),
            }
        }
        Some(ws_req::Body::MailDomainFix(r)) => {
            match c35_mod_mail::mail_domain_fix_rpc(state, ctx.caller_iid, r).await {
                Ok(body) => WsRes { req_id, body: Some(ws_res::Body::MailDomainFix(body)) },
                Err(e) => err_res(req_id, WireErr::client("mail_domain_fix_failed", e.to_string())),
            }
        }
        _ => err_res(
            req_id,
            WireErr::client("not_implemented", "Request not supported yet"),
        ),

    }
}

async fn session_init(
    ctx: &Ctx,
    mut req: c35_proto::ReqSessionInit,
    q: &WsQuery,
    geo_hint: &c35_mod_identity::GeoHint,
) -> Result<c35_proto::ResSessionInit, WireErr> {
    if req.since_ms == 0 {
        req.since_ms = q.since.unwrap_or(0);
    }
    if req.locale.is_empty() {
        req.locale = q.locale.clone().unwrap_or_default();
    }
    if req.tz.is_empty() {
        req.tz = q.tz.clone().unwrap_or_else(|| geo_hint.tz.clone());
    }
    if req.app_build == 0 {
        req.app_build = q.build.unwrap_or(0);
    }
    if req.app_version_name.is_empty() {
        req.app_version_name = q.version_name.clone().unwrap_or_default();
    }
    let hints_since_ms = req.hints_since_ms;
    let locale = if req.locale.is_empty() {
        q.locale.as_deref().unwrap_or("en").to_string()
    } else {
        req.locale.clone()
    };
    let include_inbox = req.include_inbox;
    let mut res = c35_mod_identity::session_init(ctx, req, Some(geo_hint)).await?;
    res.models = c35_mod_llm::prompt_models();
    if include_inbox {
        if let Ok(inbox) = c35_mod_chat::inbox_list(
            &ctx.pool,
            ctx.caller_iid,
            c35_proto::ReqInboxList {
                include_archived: false,
                limit: 100,
            },
        )
        .await
        {
            res.inbox_chats = inbox.chats;
            res.inbox_members = inbox.members;
        }
    }
    let mention_list = c35_mod_chat::mention_list_rpc(&ctx.pool, ctx.caller_iid).await;
    res.mentions = Some(c35_proto::MentionCatalog {
        rev: mention_list.rev,
        items: mention_list.mentions,
    });
    let locale = locale.as_str();
    if let Ok(hints) = c35_mod_hint::hint_bundle_get(&ctx.pool, ctx.caller_iid, locale, hints_since_ms).await {
        res.hints = Some(hints);
    }
    if let Some(nav) = res.nav.as_mut() {
        if let Ok((unread, visible)) = c35_mod_mail::nav_mail_snapshot(&ctx.pool, ctx.caller_iid).await {
            nav.mail_inbox_unread = unread;
            nav.mail_menu_visible = visible;
        }
    }
    Ok(res)
}

fn err_res(req_id: String, err: WireErr) -> WsRes {
    WsRes {
        req_id,
        body: Some(ws_res::Body::Err(err.into_proto())),
    }
}

async fn billing_nats_fanout(
    nats: async_nats::Client,
    owner_iid: i64,
    out_tx: mpsc::UnboundedSender<WsRes>,
) {
    let subject = format!("c35.user.{owner_iid}.>");
    let mut sub = match nats.subscribe(subject).await {
        Ok(s) => s,
        Err(e) => {
            tracing::warn!("billing nats subscribe: {e}");
            return;
        }
    };
    while let Some(msg) = sub.next().await {
        let subj = msg.subject.as_str();
        let body = if subj.ends_with(".balance") {
            BillingPushBalance::decode(msg.payload.as_ref())
                .ok()
                .map(ws_res::Body::BillingBalance)
        } else if subj.ends_with(".quota") {
            BillingPushQuota::decode(msg.payload.as_ref())
                .ok()
                .map(ws_res::Body::BillingQuota)
        } else if subj.ends_with(".commission") {
            BillingPushCommission::decode(msg.payload.as_ref())
                .ok()
                .map(ws_res::Body::BillingCommission)
        } else if subj.contains(".chat.") {
            WsRes::decode(msg.payload.as_ref()).ok().and_then(|ws| ws.body)
        } else {
            None
        };
        if let Some(body) = body {
            let req_id = if subj.contains(".chat.") {
                WsRes::decode(msg.payload.as_ref())
                    .map(|ws| ws.req_id)
                    .unwrap_or_default()
            } else {
                String::new()
            };
            let _ = out_tx.send(WsRes { req_id, body: Some(body) });
        }
    }
}

async fn send_err(socket: &mut WebSocket, req_id: &str, err: WireErr) -> Result<(), ()> {
    let res = WsRes {
        req_id: req_id.into(),
        body: Some(ws_res::Body::Err(err.into_proto())),
    };
    socket
        .send(Message::Binary(pb_encode(&res).into()))
        .await
        .map_err(|_| ())
}

fn whatsapp_worker_url() -> String {
    std::env::var("WHATSAPP_WORKER_URL").unwrap_or_default()
}

async fn pair_start_res(
    state: &AppState,
    ctx: &Ctx,
    req_id: String,
    r: ReqChannelWhatsappPairStart,
) -> WsRes {
    match c35_mod_channel::channel_whatsapp_pair_start(
        &ctx.pool,
        ctx.caller_iid,
        r.bot_iid,
        &r.channel_id,
        state.nats.as_ref(),
        &whatsapp_worker_url(),
    )
    .await
    {
        Ok(body) => WsRes {
            req_id,
            body: Some(ws_res::Body::ChannelWhatsappPairStart(body)),
        },
        Err(e) => WsRes {
            req_id,
            body: Some(ws_res::Body::ChannelWhatsappPairStart(
                c35_mod_channel::pair_res_from_error(r.bot_iid, &e),
            )),
        },
    }
}

async fn pair_watch_res(ctx: &Ctx, req_id: String, r: ReqChannelWhatsappPairWatch) -> WsRes {
    match c35_mod_channel::channel_whatsapp_pair_watch(
        &ctx.pool,
        ctx.caller_iid,
        r.bot_iid,
        &r.channel_id,
    )
    .await
    {
        Ok(body) => WsRes {
            req_id,
            body: Some(ws_res::Body::ChannelWhatsappPairWatch(body)),
        },
        Err(e) => WsRes {
            req_id,
            body: Some(ws_res::Body::ChannelWhatsappPairWatch(
                c35_mod_channel::pair_res_from_error(r.bot_iid, &e),
            )),
        },
    }
}

async fn pair_abort_res(
    state: &AppState,
    ctx: &Ctx,
    req_id: String,
    r: ReqChannelWhatsappPairAbort,
) -> WsRes {
    let res = match c35_mod_channel::channel_whatsapp_pair_abort(
        &ctx.pool,
        ctx.caller_iid,
        r.bot_iid,
        &r.channel_id,
        state.nats.as_ref(),
        &whatsapp_worker_url(),
    )
    .await
    {
        Ok(()) => ResChannelWhatsappPair {
            ok: true,
            error: String::new(),
            bot_iid: r.bot_iid,
            channel: None,
            qr_raw: String::new(),
            phone: String::new(),
        },
        Err(e) => c35_mod_channel::pair_res_from_error(r.bot_iid, &e),
    };
    WsRes {
        req_id,
        body: Some(ws_res::Body::ChannelWhatsappPairAbort(res)),
    }
}

async fn channel_disconnect_res(state: &AppState, ctx: &Ctx, req_id: String, r: ReqChannelDisconnect) -> WsRes {
    let res = c35_mod_channel::channel_disconnect(
        &ctx.pool,
        ctx.caller_iid,
        r,
        state.nats.as_ref(),
        &whatsapp_worker_url(),
    )
    .await;
    WsRes {
        req_id,
        body: Some(ws_res::Body::ChannelDisconnect(res)),
    }
}

async fn identity_delete_res(state: &AppState, ctx: &Ctx, req_id: String, r: ReqIdentityDelete) -> WsRes {
    let iid = r.iid;
    let kind = if iid > 0 {
        c35_mod_identity::identity_kind_get(&ctx.pool, iid).await.ok()
    } else {
        None
    };
    if kind.as_deref() == Some("bot") {
        let _ = c35_mod_channel::bot_channels_disconnect_all(
            &ctx.pool,
            ctx.caller_iid,
            iid,
            state.nats.as_ref(),
            &whatsapp_worker_url(),
        )
        .await;
    }
    match c35_mod_identity::identity_delete(&ctx.pool, ctx.caller_iid, r).await {
        Ok(body) => {
            if body.ok && matches!(kind.as_deref(), Some("remote") | Some("iot")) {
                let _ = c35_mod_device::device_unpair_notify(state.nats.as_ref(), iid).await;
            }
            WsRes {
                req_id,
                body: Some(ws_res::Body::IdentityDelete(body)),
            }
        }
        Err(e) => err_res(req_id, WireErr::client("identity_delete_failed", e.to_string())),
    }
}
