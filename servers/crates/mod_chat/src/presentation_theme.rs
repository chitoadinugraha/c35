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
        },
        {
            "id": "lavender",
            "label_key": "presentation.theme.lavender.label",
            "sort": 80,
            "icon": "iconify://mdi:auto-fix",
            "tokens": {
                "canvas_bg": "#0E0C1A",
                "card_bg": "#161326",
                "border": "#2E254C",
                "accent": "#A855F7",
                "accent2": "#EC4899",
                "text": "#FAF5FF",
                "subtext": "#D8B4FE",
                "badge_bg": "#3B185F",
                "bullet_card_bg": "#1AA855F7",
                "gradient_from": "#2A1647",
                "gradient_to": "#0E0C1A"
            },
            "aliases": ["amethyst", "purple", "violet"]
        },
        {
            "id": "cream",
            "label_key": "presentation.theme.cream.label",
            "sort": 90,
            "icon": "iconify://mdi:book-open-page-variant",
            "tokens": {
                "canvas_bg": "#FDFBF7",
                "card_bg": "#FFFFFF",
                "border": "#E7E1D8",
                "accent": "#C2410C",
                "accent2": "#D97706",
                "text": "#1C1917",
                "subtext": "#78716C",
                "badge_bg": "#FFEDD5",
                "bullet_card_bg": "#0CC2410C",
                "gradient_from": "#FAF5EE",
                "gradient_to": "#FDFBF7"
            },
            "aliases": ["editorial", "paper", "minimal", "warm"]
        },
        {
            "id": "monochrome",
            "label_key": "presentation.theme.monochrome.label",
            "sort": 100,
            "icon": "iconify://mdi:circle-half-full",
            "tokens": {
                "canvas_bg": "#09090B",
                "card_bg": "#131316",
                "border": "#27272A",
                "accent": "#E4E4E7",
                "accent2": "#71717A",
                "text": "#FAFAFA",
                "subtext": "#A1A1AA",
                "badge_bg": "#27272A",
                "bullet_card_bg": "#12FFFFFF",
                "gradient_from": "#202024",
                "gradient_to": "#09090B"
            },
            "aliases": ["bw", "slate", "silver", "zinc"]
        },
        {
            "id": "forest",
            "label_key": "presentation.theme.forest.label",
            "sort": 110,
            "icon": "iconify://mdi:pine-tree",
            "tokens": {
                "canvas_bg": "#08130B",
                "card_bg": "#102014",
                "border": "#1E3A24",
                "accent": "#84CC16",
                "accent2": "#A3E635",
                "text": "#F7FEE7",
                "subtext": "#BEF264",
                "badge_bg": "#1A2E05",
                "bullet_card_bg": "#1A84CC16",
                "gradient_from": "#16331C",
                "gradient_to": "#08130B"
            },
            "aliases": ["moss", "nature", "sage", "botanical"]
        },
        {
            "id": "sakura",
            "label_key": "presentation.theme.sakura.label",
            "sort": 120,
            "icon": "iconify://mdi:flower",
            "tokens": {
                "canvas_bg": "#FFF5F5",
                "card_bg": "#FFFFFF",
                "border": "#FED7D7",
                "accent": "#E11D48",
                "accent2": "#FB7185",
                "text": "#1C1917",
                "subtext": "#831843",
                "badge_bg": "#FFE4E6",
                "bullet_card_bg": "#0DE11D48",
                "gradient_from": "#FCE7F3",
                "gradient_to": "#FFF5F5"
            },
            "aliases": ["blossom", "rose-light", "pastel", "floral"]
        },
        {
            "id": "cyberpunk",
            "label_key": "presentation.theme.cyberpunk.label",
            "sort": 130,
            "icon": "iconify://mdi:controller",
            "tokens": {
                "canvas_bg": "#070614",
                "card_bg": "#100E26",
                "border": "#282054",
                "accent": "#F43F5E",
                "accent2": "#00F5FF",
                "text": "#FDF4FF",
                "subtext": "#E879F9",
                "badge_bg": "#3B0764",
                "bullet_card_bg": "#1AF43F5E",
                "gradient_from": "#2B1055",
                "gradient_to": "#070614"
            },
            "aliases": ["synthwave", "neon", "tokyo", "gaming"]
        },
        {
            "id": "coffee",
            "label_key": "presentation.theme.coffee.label",
            "sort": 140,
            "icon": "iconify://mdi:coffee",
            "tokens": {
                "canvas_bg": "#120C0A",
                "card_bg": "#1C1411",
                "border": "#362520",
                "accent": "#D97706",
                "accent2": "#EA580C",
                "text": "#FEF3C7",
                "subtext": "#D1A074",
                "badge_bg": "#2C1810",
                "bullet_card_bg": "#1AD97706",
                "gradient_from": "#2B1710",
                "gradient_to": "#120C0A"
            },
            "aliases": ["mocha", "espresso", "leather", "artisan"]
        },
        {
            "id": "aurora",
            "label_key": "presentation.theme.aurora.label",
            "sort": 150,
            "icon": "iconify://mdi:weather-night",
            "tokens": {
                "canvas_bg": "#040E1A",
                "card_bg": "#091B30",
                "border": "#13365C",
                "accent": "#2DD4BF",
                "accent2": "#818CF8",
                "text": "#F0FDFA",
                "subtext": "#5EEAD4",
                "badge_bg": "#134E4A",
                "bullet_card_bg": "#1A2DD4BF",
                "gradient_from": "#0F3559",
                "gradient_to": "#040E1A"
            },
            "aliases": ["teal", "boreal", "nordic"]
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
    fn fallback_has_sixteen_themes_and_aliases() {
        let themes = presentation_theme_fallback();
        assert_eq!(themes.len(), 16);
        let emerald = themes.iter().find(|t| t.id == "emerald").unwrap();
        assert!(emerald.aliases.contains(&"corporate".to_string()));
        let lavender = themes.iter().find(|t| t.id == "lavender").unwrap();
        assert!(lavender.aliases.contains(&"amethyst".to_string()));
        let coffee = themes.iter().find(|t| t.id == "coffee").unwrap();
        assert!(coffee.aliases.contains(&"espresso".to_string()));
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
