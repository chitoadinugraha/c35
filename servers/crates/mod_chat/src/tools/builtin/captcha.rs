use std::time::Instant;

use crate::mention_context::{device_iid_resolve, json_device_iid_field};
use crate::prompt_run::{prompt_run_get, prompt_run_is_terminal};
use crate::tool;
use crate::tools::builtin::captcha_billing::{
    captcha_billing_abort, captcha_billing_gate, captcha_billing_req_id, captcha_billing_settle,
};
use crate::tools::context::ToolContext;
use c35_mod_billing::BillingRow;
use c35_mod_captcha::{build_twocaptcha_proxy_param, CaptchaKind, SolveRequest, TwoCaptchaClient};
use c35_mod_device::{captcha_egress_hosts, device_egress_lease_mint};
use c35_proto::ReqDeviceEgressLease;
use serde_json::{json, Value};

fn arg_str(v: &Value, key: &str) -> String {
    v.get(key)
        .and_then(|x| x.as_str())
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

fn captcha_fail(error: impl Into<String>, code: &str) -> Value {
    json!({
        "ok": false,
        "error": error.into(),
        "error_code": code,
        "fail_class": "tool_error",
        "retryable": code == "not_configured" || code == "timeout",
    })
}

async fn automation_context_active(ctx: &ToolContext, device_iid: i64) -> bool {
    if ctx.req_id.trim().is_empty() {
        return false;
    }
    if let Ok(Some(row)) = prompt_run_get(&ctx.pool, &ctx.req_id).await {
        if !prompt_run_is_terminal(&row.status) {
            return true;
        }
    }
    sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS (
            SELECT 1 FROM ai.task_run
            WHERE owner_iid = $1 AND device_iid = $2 AND req_id = $3
              AND deleted_ts IS NULL
              AND status IN ('queued', 'leased', 'running')
        )
        "#,
    )
    .bind(ctx.owner_iid)
    .bind(device_iid)
    .bind(ctx.req_id.trim())
    .fetch_one(&ctx.pool)
    .await
    .unwrap_or(false)
}

tool! {
    struct: CaptchaSolveTool,
    name: "captcha.solve",
    aliases: ["captcha_solve", "solve_captcha"],
    description: "Solve a captcha during an automated browser or task run on a paired device. Returns a token to inject on the page (use with browser automation). Requires an active prompt run or in-flight browser task for this request.",
    topics: ["browser", "device"],
    rag_phrases: ["captcha", "recaptcha", "hcaptcha", "solve captcha on browser", "automation blocked by captcha"],
    ui_calling_key: "tool.captcha.solve.calling",
    ui_done_key: "tool.captcha.solve.done",
    parameters: {
        device_iid: (integer, "Paired device whose public IP should match the solver egress", required),
        kind: (string, "Captcha type: recaptcha_v2, recaptcha_v3, hcaptcha, or image", required),
        sitekey: (string, "Site key (googlekey) for widget captchas", optional),
        page_url: (string, "Page URL where the captcha is shown", optional),
        image_b64: (string, "Base64 image body for image captchas", optional),
        action: (string, "reCAPTCHA v3 action name (default verify)", optional),
        min_score: (number, "reCAPTCHA v3 minimum score (0.0-1.0)", optional),
    },
    execute: |args, ctx| {
        let direct = json_device_iid_field(&args, "device_iid");
        let device_iid = match device_iid_resolve(&ctx.mention, &ctx.mention_ids, direct) {
            Ok(iid) => iid,
            Err(e) => return Ok(captcha_fail(e.to_string(), "invalid_args")),
        };

        if !automation_context_active(ctx, device_iid).await {
            return Ok(captcha_fail(
                "captcha.solve is only allowed during an active automated prompt or browser task for this request",
                "forbidden_context",
            ));
        }

        let kind_raw = arg_str(&args, "kind");
        let kind = match CaptchaKind::parse(&kind_raw) {
            Some(k) => k,
            None => {
                return Ok(captcha_fail(
                    "kind must be recaptcha_v2, recaptcha_v3, hcaptcha, or image",
                    "invalid_args",
                ));
            }
        };

        let client = match TwoCaptchaClient::from_env() {
            Some(c) => c,
            None => {
                return Ok(captcha_fail(
                    "Captcha solver is not configured (C35_2CAPTCHA_API_KEY)",
                    "not_configured",
                ));
            }
        };

        let billing_req_id = captcha_billing_req_id(&ctx.req_id, &ctx.tool_call_id);
        let billing_row: Option<BillingRow> = if ctx.owner_iid > 0 {
            match captcha_billing_gate(&ctx.pool, ctx.owner_iid, &billing_req_id, kind).await {
                Ok(row) => Some(row),
                Err(e) => {
                    return Ok(captcha_fail(e.to_string(), "billing_insufficient"));
                }
            }
        } else {
            None
        };
        let billing_held = billing_row.is_some();

        let page_url = arg_str(&args, "page_url");
        let allow_hosts = captcha_egress_hosts(&page_url);
        let lease_req = ReqDeviceEgressLease {
            device_iid,
            req_id: ctx.req_id.clone(),
            ttl_sec: 900,
        };
        let lease = match device_egress_lease_mint(
            &ctx.pool,
            ctx.owner_iid,
            lease_req,
            Some(allow_hosts),
        )
        .await
        {
            Ok(l) => l,
            Err(e) => {
                if billing_held {
                    let _ = captcha_billing_abort(&ctx.pool, &billing_req_id).await;
                }
                return Ok(captcha_fail(e, "egress_lease_failed"));
            }
        };

        let (proxy, proxy_type) = match build_twocaptcha_proxy_param(&lease) {
            Ok(p) => p,
            Err(e) => {
                if billing_held {
                    let _ = captcha_billing_abort(&ctx.pool, &billing_req_id).await;
                }
                return Ok(captcha_fail(e, "egress_proxy_failed"));
            }
        };

        let sitekey = arg_str(&args, "sitekey");
        let image_b64 = args.get("image_b64").and_then(|v| v.as_str()).map(str::to_string);
        let action = args.get("action").and_then(|v| v.as_str()).map(str::to_string);
        let min_score = args.get("min_score").and_then(|v| v.as_f64());

        let solve_req = SolveRequest {
            kind,
            sitekey,
            page_url,
            image_b64,
            action,
            min_score,
            proxy: Some(proxy),
            proxy_type: Some(proxy_type),
        };

        let started = Instant::now();
        match client.solve(solve_req).await {
            Ok(res) => {
                let duration_ms = started.elapsed().as_millis().min(i32::MAX as u128) as i32;
                let mut charged_usd = 0.0f64;
                let mut billing_settled = false;
                if let Some(row) = billing_row.as_ref() {
                    match captcha_billing_settle(
                        &ctx.pool,
                        ctx.nats.as_ref(),
                        ctx.owner_iid,
                        row,
                        &billing_req_id,
                        &ctx.req_id,
                        kind,
                        duration_ms,
                        device_iid,
                        &res.task_id,
                    )
                    .await
                    {
                        Ok(c) => {
                            charged_usd = c;
                            billing_settled = c > 0.0;
                        }
                        Err(e) => {
                            let _ = captcha_billing_abort(&ctx.pool, &billing_req_id).await;
                            return Ok(captcha_fail(e.to_string(), "billing_failed"));
                        }
                    }
                }
                Ok(json!({
                    "ok": true,
                    "device_iid": device_iid,
                    "kind": res.kind,
                    "token": res.token,
                    "task_id": res.task_id,
                    "wholesale_usd": res.wholesale_usd,
                    "billing_settled": billing_settled,
                    "charged_usd": charged_usd,
                    "billing_req_id": billing_req_id,
                    "lease_expires_ts_ms": lease.expires_ts_ms,
                }))
            }
            Err(e) => {
                if ctx.owner_iid > 0 {
                    let _ = captcha_billing_abort(&ctx.pool, &billing_req_id).await;
                }
                Ok(captcha_fail(e.message(), e.code()))
            }
        }
    }
}
