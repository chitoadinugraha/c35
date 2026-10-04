use c35_store::missing_table;
use serde::Serialize;
use serde_json::{json, Value};
use sqlx::PgPool;
use tracing::warn;

#[derive(Debug, Clone, Serialize, serde::Deserialize)]
pub struct PresentationThemeRow {
    pub id: String,
    pub label_key: String,
    pub sort: i32,
    pub icon: String,
    pub tokens: Value,
    pub aliases: Vec<String>,
}

pub fn presentation_theme_fallback() -> Vec<PresentationThemeRow> {
    serde_json::from_value(json!([
        {
            "id": "dark",
            "label_key": "presentation.theme.dark.label",
            "sort": 0,
            "icon": "iconify://mdi:flash",
            "tokens": {
                "canvas_bg": "#0D0D11",
                "card_bg": "#141418",
                "border": "#26262C",
                "accent": "#F97316",
                "accent2": "#06B6D4",
                "text": "#F4F4F5",
                "subtext": "#A1A1AA",
                "badge_bg": "#261810",
                "bullet_card_bg": "#14FFFFFF",
                "gradient_from": "#1A1A22",
                "gradient_to": "#0E0E12"
            },
            "aliases": []
        },
        {
            "id": "midnight",
            "label_key": "presentation.theme.midnight.label",
            "sort": 10,
            "icon": "iconify://mdi:moon-waning-crescent",
            "tokens": {
                "canvas_bg": "#0B0F19",
                "card_bg": "#0F172A",
                "border": "#1E293B",
                "accent": "#6366F1",
                "accent2": "#38BDF8",
                "text": "#F8FAFC",
                "subtext": "#94A3B8",
                "badge_bg": "#1E1B4B",
                "bullet_card_bg": "#1A6366F1",
                "gradient_from": "#1E1B4B",
                "gradient_to": "#0F172A"
            },
            "aliases": ["indigo"]
        },
        {
            "id": "emerald",
            "label_key": "presentation.theme.emerald.label",
            "sort": 20,
            "icon": "iconify://mdi:leaf",
            "tokens": {
                "canvas_bg": "#041C16",
                "card_bg": "#062820",
                "border": "#0D4236",
                "accent": "#10B981",
                "accent2": "#34D399",
                "text": "#ECFDF5",
                "subtext": "#6EE7B7",
                "badge_bg": "#064E3B",
                "bullet_card_bg": "#1A10B981",
                "gradient_from": "#064E3B",
                "gradient_to": "#041C16"
            },
            "aliases": ["corporate", "mint"]
        },
        {
            "id": "sunset",
            "label_key": "presentation.theme.sunset.label",
            "sort": 30,
            "icon": "iconify://mdi:white-balance-sunny",
            "tokens": {
                "canvas_bg": "#140814",
                "card_bg": "#1E101E",
                "border": "#3A1A38",
                "accent": "#EC4899",
                "accent2": "#F59E0B",
                "text": "#FFF1F2",
                "subtext": "#FDA4AF",
                "badge_bg": "#3B0764",
                "bullet_card_bg": "#1AEC4899",
                "gradient_from": "#3B0764",
                "gradient_to": "#180816"
            },
            "aliases": ["coral", "pink"]
        },
        {
            "id": "ocean",
            "label_key": "presentation.theme.ocean.label",
            "sort": 40,
            "icon": "iconify://mdi:waves",
            "tokens": {
                "canvas_bg": "#030712",
                "card_bg": "#0B1220",
                "border": "#1E3A5F",
                "accent": "#22D3EE",
                "accent2": "#3B82F6",
                "text": "#F0F9FF",
                "subtext": "#7DD3FC",
                "badge_bg": "#0C4A6E",
                "bullet_card_bg": "#1A22D3EE",
                "gradient_from": "#0C4A6E",
                "gradient_to": "#030712"
            },
            "aliases": ["cyan", "aqua"]
        },
        {
            "id": "ruby",
            "label_key": "presentation.theme.ruby.label",
            "sort": 50,
            "icon": "iconify://mdi:gem",
            "tokens": {
                "canvas_bg": "#0F0507",
                "card_bg": "#1A0A0E",
                "border": "#4A1D28",
                "accent": "#FB7185",
                "accent2": "#F43F5E",
                "text": "#FFF1F2",
                "subtext": "#FDA4AF",
                "badge_bg": "#4C0519",
                "bullet_card_bg": "#1AFB7185",
                "gradient_from": "#4C0519",
                "gradient_to": "#0F0507"
            },
            "aliases": ["rose", "red"]
        },
        {
            "id": "gold",
            "label_key": "presentation.theme.gold.label",
            "sort": 60,
            "icon": "iconify://mdi:crown",
            "tokens": {
                "canvas_bg": "#0A0908",
                "card_bg": "#14110E",
                "border": "#3D3428",
                "accent": "#FACC15",
                "accent2": "#F59E0B",
                "text": "#FEFCE8",
                "subtext": "#FDE68A",
                "badge_bg": "#422006",
                "bullet_card_bg": "#1AFACC15",
                "gradient_from": "#422006",
                "gradient_to": "#0A0908"
            },
            "aliases": ["amber", "yellow"]
        },
        {
            "id": "arctic",
            "label_key": "presentation.theme.arctic.label",
            "sort": 70,
            "icon": "iconify://mdi:snowflake",
            "tokens": {
                "canvas_bg": "#F1F5F9",
                "card_bg": "#FFFFFF",
                "border": "#CBD5E1",
                "accent": "#0369A1",
                "accent2": "#0284C7",
                "text": "#0F172A",
                "subtext": "#475569",
                "badge_bg": "#E0F2FE",
                "bullet_card_bg": "#140369A1",
                "gradient_from": "#E2E8F0",
                "gradient_to": "#F8FAFC"
            },
            "aliases": ["light", "white"]
        }
    ]))
    .unwrap_or_default()
}

pub async fn presentation_theme_list(pool: &PgPool) -> Vec<PresentationThemeRow> {
    let rows = sqlx::query_as::<_, (String, String, i32, String, Value, Vec<String>)>(
        "SELECT id, label_key, sort, icon, tokens_json, aliases \
         FROM ai.presentation_theme WHERE enabled = true ORDER BY sort ASC, id ASC",
    )
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) if !rows.is_empty() => rows
            .into_iter()
            .map(|(id, label_key, sort, icon, tokens, aliases)| PresentationThemeRow {
                id,
                label_key,
                sort,
                icon,
                tokens,
                aliases,
            })
            .collect(),
        Ok(_) => presentation_theme_fallback(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "presentation_theme_list: table missing");
            presentation_theme_fallback()
        }
        Err(e) => {
            warn!(error = %e, "presentation_theme_list failed");
            presentation_theme_fallback()
        }
    }
}

pub async fn presentation_theme_resolve(pool: &PgPool, theme_ref: &str) -> PresentationThemeRow {
    let key = theme_ref.trim().to_lowercase();
    if key.is_empty() {
        return presentation_theme_resolve_id(pool, "dark").await;
    }
    let themes = presentation_theme_list(pool).await;
    for t in &themes {
        if t.id == key {
            return t.clone();
        }
        if t.aliases.iter().any(|a| a.eq_ignore_ascii_case(&key)) {
            return t.clone();
        }
    }
    presentation_theme_resolve_id(pool, "dark").await
}

async fn presentation_theme_resolve_id(pool: &PgPool, id: &str) -> PresentationThemeRow {
    presentation_theme_list(pool)
        .await
        .into_iter()
        .find(|t| t.id == id)
        .unwrap_or_else(|| presentation_theme_fallback().into_iter().next().expect("dark theme"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fallback_has_eight_themes_and_aliases() {
        let themes = presentation_theme_fallback();
        assert_eq!(themes.len(), 8);
        let emerald = themes.iter().find(|t| t.id == "emerald").unwrap();
        assert!(emerald.aliases.contains(&"corporate".to_string()));
    }

    #[tokio::test]
    async fn resolve_unknown_falls_back_to_dark() {
        let pool = sqlx::PgPool::connect_lazy("postgres://localhost/test").unwrap();
        let row = presentation_theme_resolve(&pool, "not-a-theme").await;
        assert_eq!(row.id, "dark");
    }

    #[tokio::test]
    async fn resolve_alias_corporate_to_emerald() {
        let pool = sqlx::PgPool::connect_lazy("postgres://localhost/test").unwrap();
        let row = presentation_theme_resolve(&pool, "corporate").await;
        assert_eq!(row.id, "emerald");
    }
}
