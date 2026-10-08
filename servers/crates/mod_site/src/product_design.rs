use serde_json::Value;

fn font_weight_css(raw: &str) -> u16 {
    match raw.trim() {
        "w300" | "light" => 300,
        "w400" | "regular" | "normal" => 400,
        "w500" | "medium" => 500,
        "w600" | "semibold" | "semiBold" => 600,
        "w700" | "bold" => 700,
        "w800" | "extraBold" => 800,
        "w900" | "black" => 900,
        _ => 600,
    }
}

fn role_style(design: &Value, role: &str) -> String {
    let size_key = format!("{role}FontSize");
    let weight_key = format!("{role}FontWeight");
    let family_key = format!("{role}FontFamily");
    let italic_key = format!("{role}Italic");
    let underline_key = format!("{role}Underline");
    let color_key = format!("{role}Color");

    let mut parts = Vec::new();
    if let Some(size) = design.get(&size_key).and_then(|x| x.as_f64()) {
        parts.push(format!("font-size:{size}px"));
    }
    if let Some(w) = design.get(&weight_key).and_then(|x| x.as_str()) {
        parts.push(format!("font-weight:{}", font_weight_css(w)));
    }
    if let Some(family) = design.get(&family_key).and_then(|x| x.as_str()) {
        let f = family.trim();
        if !f.is_empty() {
            parts.push(format!("font-family:{}", f));
        }
    }
    if design.get(italic_key).and_then(|x| x.as_bool()) == Some(true) {
        parts.push("font-style:italic".into());
    }
    if design.get(underline_key).and_then(|x| x.as_bool()) == Some(true) {
        parts.push("text-decoration:underline".into());
    }
    if let Some(color) = design.get(color_key).and_then(|x| x.as_str()) {
        let c = color.trim();
        if !c.is_empty() {
            parts.push(format!("color:{}", c));
        }
    }
    parts.join(";")
}

pub fn product_design_from_site_meta(meta: &Value) -> Option<Value> {
    meta.get("product_design")
        .filter(|v| v.is_object())
        .cloned()
}

pub fn product_card_title_style(design: Option<&Value>) -> String {
    design.map(|d| role_style(d, "title")).unwrap_or_default()
}

pub fn product_card_subtitle_style(design: Option<&Value>) -> String {
    design.map(|d| role_style(d, "subtitle")).unwrap_or_default()
}

pub fn product_card_price_style(design: Option<&Value>) -> String {
    design.map(|d| role_style(d, "price")).unwrap_or_default()
}
