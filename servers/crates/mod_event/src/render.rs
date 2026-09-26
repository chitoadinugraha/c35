use serde_json::Value;

fn scalar_str(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        Value::Bool(b) => b.to_string(),
        _ => String::new(),
    }
}

pub fn render_en(template: &str, name: &str, alien_id: Option<&str>, meta: &Value) -> String {
    let handle = alien_id
        .filter(|s| !s.is_empty())
        .map(|s| format!("@{s}"))
        .unwrap_or_else(|| "@user".into());
    let mut out = template.replace("$name", name).replace("$alien_id", &handle);
    if let Some(obj) = meta.as_object() {
        for (k, v) in obj {
            out = out.replace(&format!("${}", k), &scalar_str(v));
        }
    }
    out
}
