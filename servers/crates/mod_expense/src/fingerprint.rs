use super::types::ExpenseItem;

pub fn expense_fingerprint(items: &[ExpenseItem]) -> String {
    let mut parts: Vec<String> = items
        .iter()
        .map(|i| {
            let name = if i.name_id.trim().is_empty() {
                i.name.trim().to_lowercase()
            } else {
                i.name_id.trim().to_lowercase()
            };
            format!("{name}:{:.2}:{}", i.qty, i.total_minor)
        })
        .collect();
    parts.sort();
    blake3::hash(parts.join("|").as_bytes()).to_hex().to_string()
}

pub fn expense_total_minor(items: &[ExpenseItem]) -> i64 {
    items.iter().map(|i| i.total_minor).sum()
}

pub fn item_name_label(items: &[ExpenseItem], locale: &str) -> String {
    let names: Vec<String> = items
        .iter()
        .map(|i| {
            let name = i.name.trim();
            if name.is_empty() { i.name_id.trim() } else { name }
        })
        .filter(|s| !s.is_empty())
        .take(2)
        .map(|s| s.replace('|', "/"))
        .collect();
    if names.is_empty() {
        if locale.to_lowercase().starts_with("id") {
            "Pembelian".into()
        } else {
            "Purchase".into()
        }
    } else {
        names.join(" + ")
    }
}
