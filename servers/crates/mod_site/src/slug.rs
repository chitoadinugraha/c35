use anyhow::Result;
use sqlx::PgPool;

/// Normalizes a human-readable brand or site name into a URL-friendly slug (`alien_id`).
///
/// Rules:
/// - Lowercase
/// - Whitespace and underscores become hyphens `-`
/// - Strips non-alphanumeric characters (except hyphens and underscores)
/// - Collapses contiguous hyphens into a single hyphen
/// - Trims leading and trailing hyphens
/// - Max length 48 chars (safe within 64-char DB limit)
/// - Fallback to `"site"` if empty
pub fn site_slug_generate(name: &str) -> String {
    let trimmed = name.trim().to_lowercase();
    let mut out = String::with_capacity(trimmed.len());

    for ch in trimmed.chars() {
        if ch.is_ascii_alphanumeric() {
            out.push(ch);
        } else if ch.is_whitespace() || ch == '_' || ch == '-' {
            if !out.ends_with('-') {
                out.push('-');
            }
        }
    }

    let cleaned = out.trim_matches('-').to_string();
    let limited = if cleaned.len() > 48 {
        cleaned[..48].trim_end_matches('-').to_string()
    } else {
        cleaned
    };

    if limited.is_empty() {
        "site".to_string()
    } else {
        limited
    }
}

/// Ensures the given slug is unique among `ai.identity(kind='site')`.
/// If taken, appends `-2`, `-3`, etc.
pub async fn site_slug_ensure_unique(
    pool: &PgPool,
    base_slug: &str,
    exclude_site_iid: Option<i64>,
) -> Result<String> {
    let clean_base = if base_slug.trim().is_empty() {
        "site"
    } else {
        base_slug.trim()
    };

    // First try the clean base slug
    let exists = match exclude_site_iid {
        Some(exclude_id) => {
            sqlx::query(
                "SELECT 1 FROM ai.identity WHERE kind = 'site' AND LOWER(alien_id) = LOWER($1) AND id <> $2 AND deleted_ts IS NULL",
            )
            .bind(clean_base)
            .bind(exclude_id)
            .fetch_optional(pool)
            .await?
            .is_some()
        }
        None => {
            sqlx::query(
                "SELECT 1 FROM ai.identity WHERE kind = 'site' AND LOWER(alien_id) = LOWER($1) AND deleted_ts IS NULL",
            )
            .bind(clean_base)
            .fetch_optional(pool)
            .await?
            .is_some()
        }
    };

    if !exists {
        return Ok(clean_base.to_string());
    }

    // Append increment counter
    for counter in 2..1000 {
        let candidate = format!("{clean_base}-{counter}");
        let taken = match exclude_site_iid {
            Some(exclude_id) => {
                sqlx::query(
                    "SELECT 1 FROM ai.identity WHERE kind = 'site' AND LOWER(alien_id) = LOWER($1) AND id <> $2 AND deleted_ts IS NULL",
                )
                .bind(&candidate)
                .bind(exclude_id)
                .fetch_optional(pool)
                .await?
                .is_some()
            }
            None => {
                sqlx::query(
                    "SELECT 1 FROM ai.identity WHERE kind = 'site' AND LOWER(alien_id) = LOWER($1) AND deleted_ts IS NULL",
                )
                .bind(&candidate)
                .fetch_optional(pool)
                .await?
                .is_some()
            }
        };

        if !taken {
            return Ok(candidate);
        }
    }

    // Fallback with random suffix
    let rand_num: u32 = rand::random();
    Ok(format!("{clean_base}-{}", rand_num % 10000))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_slug_basic() {
        assert_eq!(site_slug_generate("Kopi Kenangan"), "kopi-kenangan");
        assert_eq!(site_slug_generate("  Toko Bunga  Mawar  "), "toko-bunga-mawar");
        assert_eq!(site_slug_generate("Alien & AI Co., Ltd."), "alien-ai-co-ltd");
        assert_eq!(site_slug_generate("123 Best Deals!"), "123-best-deals");
    }

    #[test]
    fn test_slug_symbols_and_accents() {
        assert_eq!(site_slug_generate("---hello---world---"), "hello-world");
        assert_eq!(site_slug_generate("Café & Bakery"), "caf-bakery");
        assert_eq!(site_slug_generate("!@#$%^&*()"), "site");
        assert_eq!(site_slug_generate(""), "site");
    }

    #[test]
    fn test_slug_max_length() {
        let long_name = "this is a very long business name that exceeds forty-eight characters definitely";
        let slug = site_slug_generate(long_name);
        assert!(slug.len() <= 48);
        assert!(!slug.ends_with('-'));
    }
}
