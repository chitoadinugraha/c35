use super::types::ConsumptionItem;

pub fn meal_fingerprint(items: &[ConsumptionItem]) -> String {
    let mut parts: Vec<String> = items
        .iter()
        .map(|i| {
            let name = if i.name_id.trim().is_empty() {
                i.name.trim().to_lowercase()
            } else {
                i.name_id.trim().to_lowercase()
            };
            format!("{name}:{:.2}", i.qty)
        })
        .collect();
    parts.sort();
    blake3::hash(parts.join("|").as_bytes()).to_hex().to_string()
}

pub fn meal_kcal_total(items: &[ConsumptionItem]) -> i32 {
    items.iter().map(|i| ((i.calories as f32) * i.qty).round() as i32).sum()
}

pub fn item_locale_name(item: &ConsumptionItem, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let label = if id && !item.name_id.trim().is_empty() {
        item.name_id.trim()
    } else if !item.name.trim().is_empty() {
        item.name.trim()
    } else if !item.name_id.trim().is_empty() {
        item.name_id.trim()
    } else {
        ""
    };
    label.replace('|', "/")
}

pub fn food_name_label(items: &[ConsumptionItem], locale: &str) -> String {
    let names: Vec<String> = items.iter().map(|i| item_locale_name(i, locale)).filter(|s| !s.is_empty()).take(2).collect();
    if names.is_empty() {
        if locale.to_lowercase().starts_with("en") {
            "Meal".into()
        } else {
            "Makanan".into()
        }
    } else {
        names.join(", ")
    }
}
