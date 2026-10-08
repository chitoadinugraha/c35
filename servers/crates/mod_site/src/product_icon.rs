use std::collections::HashMap;
use std::sync::OnceLock;
use std::time::Duration;

use anyhow::{anyhow, Result};
use serde_json::{json, Value};
use sqlx::PgPool;

/// One row in the closed product-icon catalog.
pub struct ProductIconKind {
    pub kind: &'static str,
    pub icon: &'static str,
    pub keywords: &'static [&'static str],
}

const KINDS: &[ProductIconKind] = &[
    ProductIconKind {
        kind: "coffee",
        icon: "mdi:coffee",
        keywords: &[
            "kopi",
            "coffee",
            "latte",
            "espresso",
            "americano",
            "cappuccino",
            "mocha",
            "macchiato",
        ],
    },
    ProductIconKind {
        kind: "tea",
        icon: "mdi:tea",
        keywords: &["teh", "tea", "matcha"],
    },
    ProductIconKind {
        kind: "juice",
        icon: "mdi:fruit-citrus",
        keywords: &["jus", "juice", "jeruk", "smoothie"],
    },
    ProductIconKind {
        kind: "beer",
        icon: "mdi:beer",
        keywords: &["beer", "bir"],
    },
    ProductIconKind {
        kind: "wine",
        icon: "mdi:glass-wine",
        keywords: &["wine"],
    },
    ProductIconKind {
        kind: "cocktail",
        icon: "mdi:glass-cocktail",
        keywords: &["cocktail", "mojito", "mocktail"],
    },
    ProductIconKind {
        kind: "water",
        icon: "mdi:cup-water",
        keywords: &["air mineral", "mineral water"],
    },
    ProductIconKind {
        kind: "burger",
        icon: "mdi:hamburger",
        keywords: &["burger", "hamburger"],
    },
    ProductIconKind {
        kind: "pizza",
        icon: "mdi:pizza",
        keywords: &["pizza"],
    },
    ProductIconKind {
        kind: "fries",
        icon: "mdi:french-fries",
        keywords: &["fries", "kentang goreng"],
    },
    ProductIconKind {
        kind: "rice",
        icon: "mdi:rice",
        keywords: &["nasi", "rice"],
    },
    ProductIconKind {
        kind: "noodles",
        icon: "mdi:noodles",
        keywords: &[
            "mie",
            "noodle",
            "ramen",
            "pasta",
            "spaghetti",
            "bakmi",
            "kwetiau",
        ],
    },
    ProductIconKind {
        kind: "bread",
        icon: "mdi:bread-slice",
        keywords: &["roti", "bread", "toast", "sandwich"],
    },
    ProductIconKind {
        kind: "cake",
        icon: "mdi:cake-variant",
        keywords: &["kue", "cake", "pastry", "donat", "doughnut", "croissant"],
    },
    ProductIconKind {
        kind: "ice_cream",
        icon: "mdi:ice-cream",
        keywords: &["es krim", "ice cream", "gelato", "krim"],
    },
    ProductIconKind {
        kind: "chicken",
        icon: "mdi:food-drumstick",
        keywords: &["ayam", "chicken"],
    },
    ProductIconKind {
        kind: "meat",
        icon: "mdi:food-steak",
        keywords: &["steak", "daging", "sapi", "beef"],
    },
    ProductIconKind {
        kind: "fish",
        icon: "mdi:fish",
        keywords: &["ikan", "fish", "seafood", "udang", "shrimp"],
    },
    ProductIconKind {
        kind: "soup",
        icon: "mdi:bowl",
        keywords: &["soup", "soto", "bakso"],
    },
    ProductIconKind {
        kind: "egg",
        icon: "mdi:egg",
        keywords: &["telur", "egg", "omelet", "omelette"],
    },
    ProductIconKind {
        kind: "drink",
        icon: "mdi:cup",
        keywords: &["minuman", "drink", "soda", "milkshake", "float", "lemonade"],
    },
    ProductIconKind {
        kind: "generic",
        icon: "mdi:shopping",
        keywords: &[],
    },
];

const STOP_TOKENS: &[&str] = &[
    "es", "ice", "iced", "hot", "panas", "dingin", "cold", "warm", "large", "small", "medium",
    "regular", "jumbo", "big", "pcs", "pc", "ml", "gr", "gram", "kg", "oz", "liter", "l",
    "spesial", "special", "original", "new",
];

const CLASSIFY_SYSTEM: &str = "\
Pick one kind for this product name. Reply with JSON only: {\"kind\":\"<id>\"}.
Ids: coffee, tea, juice, beer, wine, cocktail, water, burger, pizza, fries, rice, noodles, bread, cake, ice_cream, chicken, meat, fish, soup, egg, drink, generic.
Use generic when it is not food or drink. Do not explain.";

const GENERIC_ICON: &str = "mdi:shopping";

pub fn product_icon_kinds() -> &'static [ProductIconKind] {
    KINDS
}

/// Trim, lowercase, keep Unicode letters, drop size/temperature/unit tokens.
pub fn product_icon_name_key(name: &str) -> String {
    let lower = name.trim().to_lowercase();
    let spaced: String = lower
        .chars()
        .map(|ch| if ch.is_alphabetic() { ch } else { ' ' })
        .collect();
    spaced
        .split_whitespace()
        .filter(|token| !is_stop_token(token) && !is_digit_only(token))
        .collect::<Vec<_>>()
        .join(" ")
}

/// Keyword tokens must appear as a contiguous slice of `name_key` tokens.
pub fn product_icon_kind_from_rules(name_key: &str) -> Option<&'static str> {
    KINDS.iter().find_map(|row| {
        if row.keywords.iter().any(|kw| keyword_token_match(name_key, kw)) {
            Some(row.kind)
        } else {
            None
        }
    })
}

pub fn product_icon_id(kind: &str) -> &'static str {
    KINDS
        .iter()
        .find(|row| row.kind == kind)
        .map(|row| row.icon)
        .unwrap_or(GENERIC_ICON)
}

/// `name_key` → icon id. Query errors yield an empty map.
pub async fn product_icon_lookup(pool: &PgPool, name_keys: &[String]) -> HashMap<String, String> {
    if name_keys.is_empty() {
        return HashMap::new();
    }
    let rows = sqlx::query_as::<_, (String, String)>(
        r#"
        SELECT name_key, icon
        FROM site.product_icon
        WHERE name_key = ANY($1)
        "#,
    )
    .bind(name_keys)
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.into_iter().collect()
}

/// Resolve an icon id for `name`. Writes nothing when the name key is empty.
/// Lookup hit returns the stored icon. A rule hit upserts `source = rule`.
/// Otherwise one cheap-model classify runs. Failure stores `generic` / `mdi:shopping`
/// so the same key is not sent again. Conflict keeps the first writer, then re-reads.
pub async fn product_icon_ensure(pool: &PgPool, name: &str) -> String {
    let key = product_icon_name_key(name);
    if key.is_empty() {
        return GENERIC_ICON.to_string();
    }
    let keys = [key.clone()];
    if let Some(icon) = product_icon_lookup(pool, &keys).await.get(&key) {
        return icon.clone();
    }
    let (kind, source, model) = if let Some(kind) = product_icon_kind_from_rules(&key) {
        (kind.to_string(), "rule", String::new())
    } else {
        match product_icon_classify(&key).await {
            Ok(kind) if kind_in_catalog(&kind) => (kind, "llm", c35_mod_llm::CHEAP_MODEL.to_string()),
            _ => ("generic".to_string(), "llm", c35_mod_llm::CHEAP_MODEL.to_string()),
        }
    };
    let icon = product_icon_id(&kind).to_string();
    if let Err(err) = sqlx::query(
        r#"
        INSERT INTO site.product_icon (name_key, icon, kind, source, model)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (name_key) DO NOTHING
        "#,
    )
    .bind(&key)
    .bind(&icon)
    .bind(&kind)
    .bind(source)
    .bind(&model)
    .execute(pool)
    .await
    {
        tracing::debug!(name_key = %key, error = %err, "product icon upsert failed");
    }
    if let Some(stored) = product_icon_lookup(pool, &keys).await.get(&key) {
        return stored.clone();
    }
    icon
}

async fn product_icon_classify(name_key: &str) -> Result<String> {
    let key = std::env::var("GEMINI_API_KEY")
        .or_else(|_| std::env::var("GOOGLE_API_KEY"))
        .or_else(|_| std::env::var("GOOGLE_CLOUD_API_KEY"))
        .map_err(|_| anyhow!("GEMINI_API_KEY not set"))?;
    let model = c35_mod_llm::CHEAP_MODEL;
    let body = json!({
        "systemInstruction": {
            "parts": [{ "text": CLASSIFY_SYSTEM }]
        },
        "contents": [{
            "role": "user",
            "parts": [{ "text": name_key }]
        }],
        "generationConfig": {
            "temperature": 0,
            "maxOutputTokens": 32,
            "thinkingConfig": {
                "thinkingBudget": 0,
                "includeThoughts": false
            }
        }
    });
    c35_mod_llm::gemini_request_reject_provider_grounding(&body)?;
    let url = format!(
        "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    );
    let res = product_icon_http()
        .post(&url)
        .json(&body)
        .send()
        .await
        .map_err(|err| anyhow!("product icon classify request failed: {err}"))?;
    let status = res.status();
    let payload = res
        .text()
        .await
        .map_err(|err| anyhow!("product icon classify read failed: {err}"))?;
    if !status.is_success() {
        tracing::debug!(
            name_key,
            kind = "",
            prompt_tokens = 0_i64,
            output_tokens = 0_i64,
            "product icon classify"
        );
        return Err(anyhow!("product icon classify error ({status})"));
    }
    let v: Value = serde_json::from_str(&payload).map_err(|err| anyhow!("product icon classify json: {err}"))?;
    let prompt_tokens = v
        .pointer("/usageMetadata/promptTokenCount")
        .and_then(|n| n.as_i64())
        .unwrap_or(0);
    let output_tokens = v
        .pointer("/usageMetadata/candidatesTokenCount")
        .and_then(|n| n.as_i64())
        .unwrap_or(0);
    let raw = candidate_text(&v);
    let kind = parse_kind(&raw).unwrap_or_default();
    tracing::debug!(
        name_key,
        kind = %kind,
        prompt_tokens,
        output_tokens,
        "product icon classify"
    );
    if kind_in_catalog(&kind) {
        Ok(kind)
    } else {
        Err(anyhow!("product icon classify kind not in catalog"))
    }
}

fn product_icon_http() -> reqwest::Client {
    static CLIENT: OnceLock<reqwest::Client> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            reqwest::Client::builder()
                .timeout(Duration::from_secs(4))
                .build()
                .unwrap_or_else(|_| reqwest::Client::new())
        })
        .clone()
}

fn candidate_text(v: &Value) -> String {
    let Some(parts) = v.pointer("/candidates/0/content/parts").and_then(|p| p.as_array()) else {
        return String::new();
    };
    let mut out = String::new();
    for part in parts {
        if part.get("thought").and_then(|t| t.as_bool()).unwrap_or(false) {
            continue;
        }
        if let Some(text) = part.get("text").and_then(|t| t.as_str()) {
            out.push_str(text);
        }
    }
    out
}

fn parse_kind(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    let slice = match (trimmed.find('{'), trimmed.rfind('}')) {
        (Some(start), Some(end)) if end >= start => &trimmed[start..=end],
        _ => trimmed,
    };
    let v: Value = serde_json::from_str(slice).ok()?;
    let kind = v.get("kind")?.as_str()?.trim();
    if kind.is_empty() {
        None
    } else {
        Some(kind.to_string())
    }
}

fn kind_in_catalog(kind: &str) -> bool {
    KINDS.iter().any(|row| row.kind == kind)
}

fn keyword_token_match(name_key: &str, keyword: &str) -> bool {
    let name_tokens: Vec<&str> = name_key.split_whitespace().collect();
    let kw_tokens: Vec<&str> = keyword.split_whitespace().collect();
    if kw_tokens.is_empty() || kw_tokens.len() > name_tokens.len() {
        return false;
    }
    name_tokens
        .windows(kw_tokens.len())
        .any(|window| window == kw_tokens.as_slice())
}

fn is_stop_token(token: &str) -> bool {
    STOP_TOKENS.contains(&token)
}

fn is_digit_only(token: &str) -> bool {
    !token.is_empty() && token.chars().all(|ch| ch.is_ascii_digit())
}


/// One icon id per `(pic, name)`. A photo clears the icon. A lookup miss returns
/// `mdi:shopping` and classifies in the background so the next read can leave generic.
pub async fn product_icon_ids(pool: &PgPool, rows: &[(String, String)]) -> Vec<String> {
    let mut keys = Vec::new();
    for (pic, name) in rows {
        if pic.trim().is_empty() {
            let key = product_icon_name_key(name);
            if !key.is_empty() {
                keys.push(key);
            }
        }
    }
    let found = product_icon_lookup(pool, &keys).await;
    let mut spawned = std::collections::HashSet::new();
    rows.iter()
        .map(|(pic, name)| {
            if !pic.trim().is_empty() {
                return String::new();
            }
            let key = product_icon_name_key(name);
            if let Some(icon) = found.get(&key) {
                return icon.clone();
            }
            if let Some(kind) = product_icon_kind_from_rules(&key) {
                if spawned.insert(key.clone()) {
                    let pool = pool.clone();
                    let name = name.clone();
                    tokio::spawn(async move {
                        product_icon_ensure(&pool, &name).await;
                    });
                }
                return product_icon_id(kind).to_string();
            }
            if !key.is_empty() && spawned.insert(key) {
                let pool = pool.clone();
                let name = name.clone();
                tokio::spawn(async move {
                    product_icon_ensure(&pool, &name).await;
                });
            }
            GENERIC_ICON.to_string()
        })
        .collect()
}
