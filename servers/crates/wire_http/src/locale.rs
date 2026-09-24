use axum::http::{header, HeaderMap};

/// Detect user locale with priority:
/// 1. Query param (?lang=id or ?lang=en)
/// 2. Cookie (alienai_lang)
/// 3. Geo IP headers (CF-IPCountry, X-Country-Code)
/// 4. Accept-Language header
/// 5. Default 'en'
pub fn detect_locale(headers: &HeaderMap, query_lang: Option<&str>) -> String {
    if let Some(ql) = query_lang {
        let q = ql.trim().to_lowercase();
        if q == "id" || q == "in" || q.starts_with("id-") {
            return "id".into();
        }
        if q == "en" || q.starts_with("en-") {
            return "en".into();
        }
    }

    if let Some(cookie) = headers.get(header::COOKIE).and_then(|v| v.to_str().ok()) {
        for part in cookie.split(';') {
            let part = part.trim();
            if let Some(val) = part.strip_prefix("alienai_lang=") {
                let v = val.trim().to_lowercase();
                if v == "id" || v == "in" {
                    return "id".into();
                }
                if v == "en" {
                    return "en".into();
                }
            }
        }
    }

    if let Some(country) = headers
        .get("cf-ipcountry")
        .or_else(|| headers.get("x-country-code"))
        .or_else(|| headers.get("geoip-country-code"))
        .and_then(|v| v.to_str().ok())
    {
        if country.trim().eq_ignore_ascii_case("ID") {
            return "id".into();
        }
    }

    if let Some(accept) = headers.get(header::ACCEPT_LANGUAGE).and_then(|v| v.to_str().ok()) {
        let mut id_score = 0.0f32;
        let mut en_score = 0.0f32;
        for part in accept.split(',') {
            let mut segs = part.split(';');
            let tag = segs.next().unwrap_or("").trim().to_lowercase();
            let q: f32 = segs
                .find_map(|s| s.trim().strip_prefix("q="))
                .and_then(|s| s.parse().ok())
                .unwrap_or(1.0);
            if tag.starts_with("id") || tag.starts_with("in") {
                id_score = id_score.max(q);
            } else if tag.starts_with("en") {
                en_score = en_score.max(q);
            }
        }
        if id_score > en_score {
            return "id".into();
        }
    }

    "en".into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_locale_query() {
        let headers = HeaderMap::new();
        assert_eq!(detect_locale(&headers, Some("id")), "id");
        assert_eq!(detect_locale(&headers, Some("en")), "en");
    }

    #[test]
    fn test_detect_locale_geo() {
        let mut headers = HeaderMap::new();
        headers.insert("cf-ipcountry", "ID".parse().unwrap());
        assert_eq!(detect_locale(&headers, None), "id");
        headers.insert("cf-ipcountry", "US".parse().unwrap());
        assert_eq!(detect_locale(&headers, None), "en");
    }

    #[test]
    fn test_detect_locale_cookie() {
        let mut headers = HeaderMap::new();
        headers.insert(header::COOKIE, "alienai_lang=id".parse().unwrap());
        assert_eq!(detect_locale(&headers, None), "id");
    }
}
