pub fn proxy_env() -> Vec<(String, String)> {
    let mut pairs = Vec::new();
    for key in ["ALIENAI_PROXY_CF_URL", "HTTP_PROXY", "HTTPS_PROXY"] {
        if let Ok(v) = std::env::var(key) {
            let v = v.trim();
            if !v.is_empty() {
                pairs.push(("HTTP_PROXY".into(), v.to_string()));
                pairs.push(("HTTPS_PROXY".into(), v.to_string()));
                break;
            }
        }
    }
    pairs
}