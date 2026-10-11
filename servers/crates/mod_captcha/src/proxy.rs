use c35_proto::ResDeviceEgressLease;

/// Build `proxy=` value for 2Captcha (`user:pass@host:port`).
pub fn build_twocaptcha_proxy_param(lease: &ResDeviceEgressLease) -> Result<(String, String), String> {
    let proxy_url = lease.proxy_url.trim();
    if proxy_url.is_empty() {
        return Err("egress lease missing proxy_url".into());
    }
    let (scheme, host_port) = split_proxy_url(proxy_url)?;
    let proxy_type = match scheme.as_str() {
        "https" => "HTTPS",
        "http" => "HTTP",
        _ => return Err("unsupported egress proxy scheme".into()),
    };
    let user = lease.username.trim();
    let pass = lease.password.trim();
    if user.is_empty() || pass.is_empty() {
        return Err("egress lease missing proxy credentials".into());
    }
    let param = format!("{}:{}@{}", user, pass, host_port);
    Ok((param, proxy_type.to_string()))
}

fn split_proxy_url(proxy_url: &str) -> Result<(String, String), String> {
    let s = proxy_url.trim();
    let lower = s.to_ascii_lowercase();
    let (scheme, rest) = if let Some(r) = lower.strip_prefix("https://") {
        ("https", r)
    } else if let Some(r) = lower.strip_prefix("http://") {
        ("http", r)
    } else {
        return Err("proxy_url must be http(s)://host:port".into());
    };
    let host_port = rest.split('/').next().unwrap_or(rest).trim();
    if host_port.is_empty() {
        return Err("proxy_url missing host".into());
    }
    Ok((scheme.to_string(), host_port.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_proxy_param() {
        let lease = ResDeviceEgressLease {
            proxy_url: "https://proxy.alienai.id:443".into(),
            username: "12345".into(),
            password: "secret".into(),
            expires_ts_ms: 0,
            device_iid: 1,
        };
        let (p, ty) = build_twocaptcha_proxy_param(&lease).expect("proxy");
        assert_eq!(p, "12345:secret@proxy.alienai.id:443");
        assert_eq!(ty, "HTTPS");
    }

    #[test]
    fn rejects_bad_url() {
        let lease = ResDeviceEgressLease {
            proxy_url: "socks5://x".into(),
            username: "a".into(),
            password: "b".into(),
            expires_ts_ms: 0,
            device_iid: 1,
        };
        assert!(build_twocaptcha_proxy_param(&lease).is_err());
    }
}
