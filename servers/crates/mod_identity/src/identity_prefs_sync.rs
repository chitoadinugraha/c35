use sqlx::PgPool;

fn trim_cap(s: &str, max: usize) -> String {
    s.trim().chars().take(max).collect()
}

fn location_source_for_sync(location_source: &str) -> &'static str {
    match location_source.trim().to_ascii_lowercase().as_str() {
        "device" => "device",
        _ => "user",
    }
}

pub async fn identity_prefs_sync(
    pool: &PgPool,
    caller_iid: i64,
    locale: &str,
    tz: &str,
    location_city: &str,
    location_region: &str,
    location_country: &str,
    location_source: &str,
) -> Result<(), String> {
    let locale = trim_cap(locale, 16);
    let tz = trim_cap(tz, 64);
    let city = trim_cap(location_city, 80);
    let region = trim_cap(location_region, 80);
    let country = trim_cap(location_country, 8).to_ascii_uppercase();

    let touch_location = !city.is_empty() || !region.is_empty() || !country.is_empty();
    let touch_locale = !locale.is_empty();
    let touch_tz = !tz.is_empty();
    if !touch_location && !touch_locale && !touch_tz {
        return Ok(());
    }

    let loc_source = location_source_for_sync(location_source);

    sqlx::query(
        r#"
        UPDATE ai.identity SET
            locale = CASE WHEN $2 <> '' THEN $2 ELSE locale END,
            tz = CASE WHEN $3 <> '' THEN $3 ELSE tz END,
            meta = CASE
                WHEN $4 <> '' OR $5 <> '' OR $6 <> '' THEN
                    jsonb_set(
                        jsonb_set(
                            jsonb_set(
                                jsonb_set(
                                    COALESCE(meta, '{}'::jsonb),
                                    '{location,city}',
                                    to_jsonb($4::text),
                                    true
                                ),
                                '{location,region}',
                                to_jsonb($5::text),
                                true
                            ),
                            '{location,country}',
                            to_jsonb($6::text),
                            true
                        ),
                        '{location,source}',
                        to_jsonb($7::text),
                        true
                    )
                ELSE meta
            END,
            updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(caller_iid)
    .bind(&locale)
    .bind(&tz)
    .bind(&city)
    .bind(&region)
    .bind(&country)
    .bind(loc_source)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}
