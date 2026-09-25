use axum::http::HeaderMap;
use sqlx::PgPool;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct GeoHint {
    pub city: String,
    pub region: String,
    pub country: String,
    pub tz: String,
}

impl GeoHint {
    pub fn is_empty(&self) -> bool {
        self.city.is_empty() && self.region.is_empty() && self.country.is_empty() && self.tz.is_empty()
    }
}

fn header_str(headers: &HeaderMap, name: &str) -> Option<String> {
    headers
        .get(name)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty() && !s.eq_ignore_ascii_case("xx"))
}

fn trim_cap(s: &str, max: usize) -> String {
    s.trim().chars().take(max).collect()
}

fn tz_from_country(country: &str) -> &'static str {
    match country.trim().to_ascii_uppercase().as_str() {
        "ID" => "Asia/Jakarta",
        "SG" | "MY" => "Asia/Singapore",
        "JP" => "Asia/Tokyo",
        "AU" => "Australia/Sydney",
        "GB" | "IE" => "Europe/London",
        "DE" | "FR" | "NL" | "IT" | "ES" => "Europe/Berlin",
        "US" => "America/New_York",
        _ => "",
    }
}

/// Cloudflare / reverse-proxy geo headers (no client permission).
pub fn identity_geo_from_headers(headers: &HeaderMap) -> GeoHint {
    let country = header_str(headers, "cf-ipcountry")
        .or_else(|| header_str(headers, "x-country-code"))
        .or_else(|| header_str(headers, "geoip-country-code"))
        .map(|s| s.to_ascii_uppercase())
        .unwrap_or_default();
    let city = header_str(headers, "cf-ipcity").or_else(|| header_str(headers, "x-city")).unwrap_or_default();
    let region = header_str(headers, "cf-region")
        .or_else(|| header_str(headers, "cf-region-code"))
        .or_else(|| header_str(headers, "x-region"))
        .unwrap_or_default();
    let tz = header_str(headers, "cf-timezone")
        .or_else(|| header_str(headers, "x-timezone"))
        .unwrap_or_else(|| tz_from_country(&country).to_string());
    GeoHint {
        city: trim_cap(&city, 80),
        region: trim_cap(&region, 80),
        country: trim_cap(&country, 8),
        tz: trim_cap(&tz, 64),
    }
}

/// Fill location/tz from IP when the user has not set a city (source != user).
pub async fn identity_geo_ip_apply(pool: &PgPool, caller_iid: i64, geo: &GeoHint) -> Result<(), String> {
    if geo.is_empty() {
        return Ok(());
    }
    sqlx::query(
        r#"
        UPDATE ai.identity SET
            tz = CASE
                WHEN COALESCE(tz, '') IN ('', 'UTC') AND $2 <> '' THEN $2
                ELSE tz
            END,
            meta = CASE
                WHEN COALESCE(meta #>> '{location,source}', '') NOT IN ('user', 'device')
                  AND ($3 <> '' OR $4 <> '' OR $5 <> '') THEN
                    jsonb_set(
                        jsonb_set(
                            jsonb_set(
                                jsonb_set(
                                    COALESCE(meta, '{}'::jsonb),
                                    '{location,city}',
                                    to_jsonb($3::text),
                                    true
                                ),
                                '{location,region}',
                                to_jsonb($4::text),
                                true
                            ),
                            '{location,country}',
                            to_jsonb($5::text),
                            true
                        ),
                        '{location,source}',
                        '"ip"'::jsonb,
                        true
                    )
                ELSE meta
            END,
            updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(caller_iid)
    .bind(&geo.tz)
    .bind(&geo.city)
    .bind(&geo.region)
    .bind(&geo.country)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn geo_from_cloudflare_headers() {
        let mut headers = HeaderMap::new();
        headers.insert("cf-ipcountry", "ID".parse().unwrap());
        headers.insert("cf-ipcity", "Malang".parse().unwrap());
        headers.insert("cf-region", "East Java".parse().unwrap());
        headers.insert("cf-timezone", "Asia/Jakarta".parse().unwrap());
        let geo = identity_geo_from_headers(&headers);
        assert_eq!(geo.country, "ID");
        assert_eq!(geo.city, "Malang");
        assert_eq!(geo.region, "East Java");
        assert_eq!(geo.tz, "Asia/Jakarta");
    }

    #[test]
    fn geo_country_fallback_tz() {
        let mut headers = HeaderMap::new();
        headers.insert("cf-ipcountry", "ID".parse().unwrap());
        let geo = identity_geo_from_headers(&headers);
        assert_eq!(geo.tz, "Asia/Jakarta");
    }
}
