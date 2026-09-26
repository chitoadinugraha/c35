//! Custom-domain DNS verification (CNAME → platform target).

pub fn normalize_hostname(host: &str) -> String {
    host.trim()
        .split(':')
        .next()
        .unwrap_or("")
        .trim()
        .to_lowercase()
        .trim_end_matches('.')
        .to_string()
}

/// Expected CNAME target (`C35_DOMAIN_CNAME_TARGET`, default `site.alienai.id`).
pub fn domain_cname_target() -> String {
    std::env::var("C35_DOMAIN_CNAME_TARGET")
        .ok()
        .map(|s| normalize_hostname(&s))
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "site.alienai.id".into())
}

pub fn cname_destination_matches(dest: &str, target: &str) -> bool {
    let dest = normalize_hostname(dest);
    let target = normalize_hostname(target);
    if dest.is_empty() || target.is_empty() {
        return false;
    }
    dest == target || dest.ends_with(&format!(".{target}"))
}

async fn dns_a_addrs(resolver: &hickory_resolver::TokioAsyncResolver, name: &str) -> Result<Vec<std::net::IpAddr>, String> {
    use hickory_resolver::proto::rr::record_type::RecordType;
    let lookup = resolver
        .lookup(name, RecordType::A)
        .await
        .map_err(|e| e.to_string())?;
    Ok(lookup.iter().filter_map(|r| r.as_a().map(|a| std::net::IpAddr::V4(a.0))).collect())
}

fn addrs_match(domain_addrs: &[std::net::IpAddr], target_addrs: &[std::net::IpAddr]) -> bool {
    !domain_addrs.is_empty() && !target_addrs.is_empty() && domain_addrs.iter().any(|a| target_addrs.contains(a))
}

/// Returns `Ok(true)` when `domain` CNAME-chains to `target` or apex A matches target addresses (CF flatten).
pub async fn dns_cname_points_to(domain: &str, target: &str) -> Result<bool, String> {
    use hickory_resolver::config::{ResolverConfig, ResolverOpts};
    use hickory_resolver::proto::rr::record_type::RecordType;
    use hickory_resolver::TokioAsyncResolver;

    let domain = normalize_hostname(domain);
    let target = normalize_hostname(target);
    if domain.is_empty() || target.is_empty() {
        return Ok(false);
    }

    let resolver = TokioAsyncResolver::tokio(ResolverConfig::default(), ResolverOpts::default());
    let mut name = domain.clone();
    for _ in 0..8 {
        let lookup = match resolver.lookup(name.as_str(), RecordType::CNAME).await {
            Ok(l) => l,
            Err(_) => break,
        };
        let mut next: Option<String> = None;
        for r in lookup.iter() {
            if let Some(cname) = r.as_cname() {
                let dest = normalize_hostname(&cname.0.to_string());
                if cname_destination_matches(&dest, &target) {
                    return Ok(true);
                }
                next = Some(dest);
            }
        }
        match next {
            Some(n) if n != name => name = n,
            _ => break,
        }
    }
    let domain_a = dns_a_addrs(&resolver, &domain).await?;
    let target_a = dns_a_addrs(&resolver, &target).await?;
    Ok(addrs_match(&domain_a, &target_a))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn domain_cname_target_default() {
        std::env::remove_var("C35_DOMAIN_CNAME_TARGET");
        assert_eq!(domain_cname_target(), "site.alienai.id");
    }

    #[test]
    fn cname_destination_matches_exact_and_suffix() {
        assert!(cname_destination_matches("site.alienai.id", "site.alienai.id"));
        assert!(cname_destination_matches("x.site.alienai.id", "site.alienai.id"));
        assert!(!cname_destination_matches("evil.alienai.id", "site.alienai.id"));
        assert!(!cname_destination_matches("", "site.alienai.id"));
    }

    #[test]
    fn normalize_hostname_strips_port_and_dot() {
        assert_eq!(normalize_hostname(" Shop.COM:443. "), "shop.com");
        assert_eq!(normalize_hostname("api.test."), "api.test");
    }
}
