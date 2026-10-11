pub(crate) const DEFAULT_HOSTS: &[&str] = &["api.ipify.org", "ifconfig.me", "httpbin.org"];

/// Hosts allowed on an egress lease minted for `captcha.solve`.
pub fn captcha_egress_hosts(page_url: &str) -> Vec<String> {
    let mut hosts = vec![
        "2captcha.com".to_string(),
        "api.2captcha.com".to_string(),
    ];
    if let Some(h) = page_url_host(page_url) {
        hosts.push(h);
    }
    hosts.sort();
    hosts.dedup();
    hosts
}

fn page_url_host(page_url: &str) -> Option<String> {
    let s = page_url.trim();
    if s.is_empty() {
        return None;
    }
    let rest = s
        .strip_prefix("https://")
        .or_else(|| s.strip_prefix("http://"))
        .unwrap_or(s);
    let host = rest
        .split('/')
        .next()?
        .split('@')
        .next()?
        .split(':')
        .next()?
        .trim();
    if host.is_empty() {
        None
    } else {
        Some(host.to_ascii_lowercase())
    }
}

pub fn host_allowed(host: &str, allow_hosts_json: &[String]) -> bool {
    let host = host.trim().to_ascii_lowercase();
    if host.is_empty() {
        return false;
    }
    let list: Vec<String> = if allow_hosts_json.is_empty() {
        DEFAULT_HOSTS.iter().map(|h| h.to_string()).collect()
    } else {
        allow_hosts_json.to_vec()
    };
    list.iter().any(|h| h.trim().eq_ignore_ascii_case(&host))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_hosts_allow_ipify() {
        assert!(host_allowed("api.ipify.org", &[]));
        assert!(host_allowed("API.IPIFY.ORG", &[]));
    }

    #[test]
    fn custom_list_only() {
        assert!(host_allowed("example.com", &["example.com".into()]));
        assert!(!host_allowed("api.ipify.org", &["example.com".into()]));
    }

    #[test]
    fn empty_host_denied() {
        assert!(!host_allowed("  ", &[]));
    }

    #[test]
    fn captcha_hosts_include_page_and_provider() {
        let h = captcha_egress_hosts("https://www.google.com/recaptcha/api2/demo");
        assert!(h.iter().any(|x| x == "www.google.com"));
        assert!(h.iter().any(|x| x == "2captcha.com"));
        assert!(h.iter().any(|x| x == "api.2captcha.com"));
    }
}
