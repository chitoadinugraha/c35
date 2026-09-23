use axum::{
    body::Bytes,
    extract::State,
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::post,
};
use c35_ctx::AppState;
use c35_mod_admin::{admin_log_list, admin_user_put, admin_user_search};
use c35_mod_billing::{
    billing_history, billing_notify_owner, billing_package_preview, billing_package_redeem,
    billing_plan_subscribe, billing_promotion_claim, billing_promotion_create, billing_promotion_get,
    billing_promotion_list_by_creator, billing_summary, billing_topup_list, billing_topup_put,
    billing_topup_review, bot_usage_stats, commission_withdraw_list, commission_withdraw_review,
    receive_account_list, receive_account_put, PromotionCreateFields,
};
use c35_mod_channel::{channel_telegram_connect, channel_whatsapp_meta_connect};
use c35_mod_consumption::consumption_put_rpc;
use c35_mod_chat::{
    inst_delete, inst_get, inst_list, inst_put, object_alias_list, object_alias_put,
    object_normalizer_list, translation_put,
};
use c35_mod_device::device_pair;
use c35_mod_voice::{voice_stt_rpc, voice_tts_rpc};
use c35_mod_identity::auth_session_caller_iid;
use c35_mod_referral::{
    commission_withdraw, referral_code_delete, referral_code_list, referral_code_put,
    referral_commission_simulate, referral_ledger_list, referral_share_set, referral_tree_get,
    referral_user_stats,
};
use c35_proto::{
    invoke_req, invoke_res, InvokeReq, InvokeRes, ResReferralShareSet, ResReferralTreeGet,
};
use prost::Message;

pub fn invoke_router() -> axum::Router<AppState> {
    axum::Router::new().route("/v1/invoke", post(http_invoke_handler))
}

async fn http_invoke_handler(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let mut req = match InvokeReq::decode(body) {
        Ok(r) => r,
        Err(e) => return text_response(StatusCode::BAD_REQUEST, format!("Protobuf decode error: {e}")),
    };
    let iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return invoke_unauthorized(&req.req_id),
    };
    req.caller_iid = iid;
    protobuf_response(dispatch_invoke(&st, req).await)
}

pub async fn dispatch_invoke(state: &AppState, req: InvokeReq) -> InvokeRes {
    let pool = &state.pool;
    let req_id = req.req_id.clone();
    let iid = req.caller_iid;
    match req.body {
        Some(invoke_req::Body::ReferralTreeGet(r)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::ReferralTreeGet(ResReferralTreeGet {
                slice: Some(referral_tree_get(&state.pool, iid, r.root_id, r.depth).await),
            })),
        },
        Some(invoke_req::Body::ReferralShareSet(r)) => {
            match referral_share_set(pool, iid, r.parent_uid, r.child_uid, r.share_percent).await {
                Ok(()) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralShareSet(ResReferralShareSet {
                        success: true,
                    })),
                },
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        Some(invoke_req::Body::ReferralCodeList(_)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::ReferralCodeList(
                c35_proto::ResReferralCodeList {
                    items: referral_code_list(pool, iid).await,
                },
            )),
        },
        Some(invoke_req::Body::ReferralCodePut(r)) => {
            let doc = r.code.unwrap_or_default();
            match referral_code_put(pool, iid, doc).await {
                Ok(saved) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralCodePut(saved)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ReferralCodeDelete(r)) => {
            match referral_code_delete(pool, iid, &r.code).await {
                Ok(()) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: None,
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ReferralUserStats(r)) => {
            match referral_user_stats(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralUserStats(res)),
                },
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        Some(invoke_req::Body::ReferralCommissionSimulate(r)) => {
            match referral_commission_simulate(pool, iid, r.subject_uid, r.purchase_amount).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ReferralCommissionSimulate(res)),
                },
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        Some(invoke_req::Body::BillingPackageRedeem(r)) => {
            match billing_package_redeem(pool, iid, &r.code).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingPackageRedeem(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::BillingPackagePreview(r)) => {
            match billing_package_preview(pool, iid, &r.code).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingPackagePreview(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::BotUsageStats(r)) => {
            match bot_usage_stats(pool, iid, r.bot_iid).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BotUsageStats(res)),
                },
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        Some(invoke_req::Body::BillingSummary(r)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::BillingSummary(
                billing_summary(pool, iid, r.billing_account_id).await,
            )),
        },
        Some(invoke_req::Body::BillingHistory(r)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::BillingHistory(billing_history(pool, iid, r).await)),
        },
        Some(invoke_req::Body::BillingPromotionCreate(r)) => {
            let code = r.code.clone();
            let fields = PromotionCreateFields {
                code: r.code,
                promo_type: r.r#type,
                audience: r.audience,
                name: r.name,
                base_plan_slug: r.base_plan_slug,
                pool_multiplier: r.pool_multiplier,
                alien_pool_idr: r.alien_pool_idr,
                frontier_pool_idr: r.frontier_pool_idr,
                duration_days: r.duration_days,
                duration_minutes: r.duration_minutes,
                max_claims_total: r.max_claims_total,
                max_claims_per_email: r.max_claims_per_email,
                valid_from_ms: r.valid_from_ms,
                valid_to_ms: r.valid_to_ms,
                scope: r.scope,
                is_active: r.is_active,
            };
            match billing_promotion_create(pool, iid, fields).await {
                Ok(promotion_id) => {
                    let promotion = billing_promotion_get(pool, &code)
                        .await
                        .ok()
                        .flatten();
                    InvokeRes {
                        req_id,
                        status_code: 200,
                        error_message: String::new(),
                        body: Some(invoke_res::Body::BillingPromotionCreate(
                            c35_proto::ResBillingPromotionCreate {
                                promotion_id,
                                promotion,
                            },
                        )),
                    }
                }
                Err(msg) => invoke_error(
                    &req_id,
                    if msg == "forbidden" { 403 } else { 400 },
                    msg,
                ),
            }
        }
        Some(invoke_req::Body::BillingPromotionClaim(r)) => {
            match billing_promotion_claim(pool, iid, &r.email, &r.code).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingPromotionClaim(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::BillingPromotionList(_)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::BillingPromotionList(
                c35_proto::ResBillingPromotionList {
                    items: billing_promotion_list_by_creator(pool, iid)
                        .await
                        .unwrap_or_default(),
                },
            )),
        },
        Some(invoke_req::Body::BillingTopupPut(r)) => {
            match billing_topup_put(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingTopupPut(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::BillingPlanSubscribe(r)) => {
            match billing_plan_subscribe(pool, iid, r).await {
                Ok(res) => {
                    billing_notify_owner(pool, state.nats.as_ref(), iid, None).await;
                    InvokeRes {
                        req_id,
                        status_code: 200,
                        error_message: String::new(),
                        body: Some(invoke_res::Body::BillingPlanSubscribe(res)),
                    }
                }
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::AdminUserSearch(r)) => {
            match admin_user_search(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::AdminUserSearch(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::AdminUserPut(r)) => {
            match admin_user_put(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::AdminUserPut(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::AdminLogList(r)) => {
            match admin_log_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::AdminLogList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::ChannelTelegramConnect(r)) => {
            match channel_telegram_connect(&state.pool, iid, &state.public_origin, r, state.nats.as_ref()).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ChannelTelegramConnect(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ChannelWhatsappMetaConnect(r)) => {
            match channel_whatsapp_meta_connect(&state.pool, iid, &state.public_origin, r, state.nats.as_ref()).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ChannelWhatsappMetaConnect(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::ConsumptionPut(r)) => {
            let locale = "en";
            match consumption_put_rpc(pool, iid, locale, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ConsumptionPut(res)),
                },
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::DevicePair(r)) => match device_pair(pool, iid, r).await {
            Ok(res) => InvokeRes {
                req_id,
                status_code: 200,
                error_message: String::new(),
                body: Some(invoke_res::Body::DevicePair(res)),
            },
            Err(msg) => invoke_error(&req_id, 400, msg),
        },
        Some(invoke_req::Body::InstList(r)) => match inst_list(pool, iid, r).await {
            Ok(res) => InvokeRes {
                req_id,
                status_code: 200,
                error_message: String::new(),
                body: Some(invoke_res::Body::InstList(res)),
            },
            Err(e) => invoke_error(&req_id, e.status_code, e.message),
        },
        Some(invoke_req::Body::InstGet(r)) => match inst_get(pool, iid, r).await {
            Ok(res) => InvokeRes {
                req_id,
                status_code: 200,
                error_message: String::new(),
                body: Some(invoke_res::Body::InstGet(res)),
            },
            Err(e) => invoke_error(&req_id, e.status_code, e.message),
        },
        Some(invoke_req::Body::InstPut(r)) => match inst_put(pool, state.nats.as_ref(), iid, r).await {
            Ok(res) => InvokeRes {
                req_id,
                status_code: 200,
                error_message: String::new(),
                body: Some(invoke_res::Body::InstPut(res)),
            },
            Err(e) => invoke_error(&req_id, e.status_code, e.message),
        },
        Some(invoke_req::Body::InstDelete(r)) => {
            match inst_delete(pool, state.nats.as_ref(), iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::InstDelete(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::TranslationPut(r)) => {
            match translation_put(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::TranslationPut(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::ObjectAliasList(r)) => {
            match object_alias_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ObjectAliasList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::ObjectAliasPut(r)) => {
            match object_alias_put(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ObjectAliasPut(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::ObjectNormalizerList(r)) => {
            match object_normalizer_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::ObjectNormalizerList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::VoiceStt(r)) => {
            let res = voice_stt_rpc(pool, state.nats.as_ref(), iid, r).await;
            let status = if res.error.is_empty() { 200 } else { 400 };
            InvokeRes {
                req_id,
                status_code: status,
                error_message: res.error.clone(),
                body: Some(invoke_res::Body::VoiceStt(res)),
            }
        }
        Some(invoke_req::Body::VoiceTts(r)) => {
            let res = voice_tts_rpc(pool, state.nats.as_ref(), iid, r).await;
            let status = if res.error.is_empty() { 200 } else { 400 };
            InvokeRes {
                req_id,
                status_code: status,
                error_message: res.error.clone(),
                body: Some(invoke_res::Body::VoiceTts(res)),
            }
        }
        Some(invoke_req::Body::BillingTopupList(r)) => {
            match billing_topup_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingTopupList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::BillingTopupReview(r)) => {
            match billing_topup_review(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingTopupReview(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::CommissionWithdraw(r)) => {
            match commission_withdraw(pool, iid, r).await {
                Ok(res) => {
                    billing_notify_owner(pool, state.nats.as_ref(), iid, None).await;
                    InvokeRes {
                        req_id,
                        status_code: 200,
                        error_message: String::new(),
                        body: Some(invoke_res::Body::CommissionWithdraw(res)),
                    }
                }
                Err(msg) => invoke_error(&req_id, 400, msg),
            }
        }
        Some(invoke_req::Body::CommissionWithdrawList(r)) => {
            match commission_withdraw_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::CommissionWithdrawList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::CommissionWithdrawReview(r)) => {
            match commission_withdraw_review(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::CommissionWithdrawReview(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::ReferralLedgerList(r)) => InvokeRes {
            req_id,
            status_code: 200,
            error_message: String::new(),
            body: Some(invoke_res::Body::ReferralLedgerList(referral_ledger_list(pool, iid, r).await)),
        },
        Some(invoke_req::Body::BillingReceiveAccountPut(r)) => {
            match receive_account_put(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingReceiveAccountPut(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        Some(invoke_req::Body::BillingReceiveAccountList(r)) => {
            match receive_account_list(pool, iid, r).await {
                Ok(res) => InvokeRes {
                    req_id,
                    status_code: 200,
                    error_message: String::new(),
                    body: Some(invoke_res::Body::BillingReceiveAccountList(res)),
                },
                Err(e) => invoke_error(&req_id, e.status_code, e.message),
            }
        }
        _ => invoke_error(&req_id, 404, "not implemented".into()),
    }
}

fn invoke_unauthorized(req_id: &str) -> Response {
    protobuf_response(InvokeRes {
        req_id: req_id.into(),
        status_code: 401,
        error_message: "unauthorized".into(),
        body: None,
    })
}

fn invoke_error(req_id: &str, status: i32, msg: String) -> InvokeRes {
    InvokeRes {
        req_id: req_id.into(),
        status_code: status,
        error_message: msg,
        body: None,
    }
}

fn protobuf_response(res: InvokeRes) -> Response {
    let status = StatusCode::from_u16(res.status_code as u16).unwrap_or(StatusCode::OK);
    let mut buf = Vec::new();
    let _ = res.encode(&mut buf);
    use axum::http::HeaderValue;
    (
        status,
        [(
            axum::http::header::CONTENT_TYPE,
            HeaderValue::from_static("application/x-protobuf"),
        )],
        buf,
    )
        .into_response()
}

fn text_response(status: StatusCode, msg: String) -> Response {
    (status, msg).into_response()
}
