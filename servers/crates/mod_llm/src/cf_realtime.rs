use crate::runtime_config::{cf_gateway_config, cf_gateway_ready};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CfRealtimeUpstream {
    OpenAi,
    Grok,
}

/// When true, smoke / live clients prefer Cloudflare AI Gateway WebSocket URLs.
/// `LIVE_REALTIME_VIA_CF`: `1` force on, `0` force off, unset = auto (`cf_gateway_ready()`).
pub fn cf_realtime_via_cf() -> bool {
    match std::env::var("LIVE_REALTIME_VIA_CF")
        .ok()
        .map(|v| v.trim().to_ascii_lowercase())
    {
        Some(v) if v == "0" || v == "false" || v == "off" || v == "no" => false,
        Some(v) if v == "1" || v == "true" || v == "on" || v == "yes" => true,
        _ => cf_gateway_ready(),
    }
}

pub fn cf_realtime_ws_url(model: &str, upstream: CfRealtimeUpstream) -> Option<String> {
    if !cf_gateway_ready() {
        return None;
    }
    let cfg = cf_gateway_config();
    if cfg.account_id.is_empty() || cfg.api_token.is_empty() {
        return None;
    }
    let model = model.trim();
    let path = match upstream {
        CfRealtimeUpstream::OpenAi => format!("openai?model={}", urlencoding::encode(model)),
        CfRealtimeUpstream::Grok => format!(
            "grok/v1/realtime?model={}",
            urlencoding::encode(model)
        ),
    };
    Some(format!(
        "wss://gateway.ai.cloudflare.com/v1/{}/{}/{}",
        cfg.account_id, cfg.gateway_id, path
    ))
}

/// Headers for CF AI Gateway realtime WebSocket (BYOK: omit provider bearer).
pub fn cf_realtime_ws_header_pairs(
    upstream: CfRealtimeUpstream,
    provider_bearer: Option<&str>,
) -> Vec<(String, String)> {
    let cfg = cf_gateway_config();
    let mut out = vec![(
        "cf-aig-authorization".to_string(),
        format!("Bearer {}", cfg.api_token.trim()),
    )];
    if let Some(k) = provider_bearer.map(str::trim).filter(|s| !s.is_empty()) {
        out.push(("Authorization".to_string(), format!("Bearer {k}")));
    }
    if matches!(upstream, CfRealtimeUpstream::OpenAi) {
        out.push(("OpenAI-Beta".to_string(), "realtime=v1".to_string()));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cf_realtime_openai_url_shape() {
        std::env::set_var("CLOUDFLARE_ACCOUNT_ID", "acct");
        std::env::set_var("CLOUDFLARE_API_TOKEN", "tok");
        std::env::set_var("CLOUDFLARE_AI_GATEWAY_ID", "gw");
        let url = cf_realtime_ws_url("gpt-4o-realtime-preview", CfRealtimeUpstream::OpenAi).unwrap();
        assert!(url.starts_with("wss://gateway.ai.cloudflare.com/v1/acct/gw/openai?model="));
        std::env::remove_var("CLOUDFLARE_ACCOUNT_ID");
        std::env::remove_var("CLOUDFLARE_API_TOKEN");
        std::env::remove_var("CLOUDFLARE_AI_GATEWAY_ID");
    }
}
