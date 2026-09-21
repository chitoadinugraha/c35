//! Convert LLM markdown to platform-native chat formatting.

struct Slot {
    key: String,
    value: String,
    fenced: bool,
}

fn slot_insert(slots: &mut Vec<Slot>, value: String, fenced: bool) -> String {
    let key = format!("\x01F{}\x01", slots.len());
    slots.push(Slot { key: key.clone(), value, fenced });
    key
}

fn protect_fenced_code(text: &str, slots: &mut Vec<Slot>) -> String {
    let mut out = text.to_string();
    while let Some(start) = out.find("```") {
        let after_open = start + 3;
        if let Some(end_rel) = out[after_open..].find("```") {
            let end = after_open + end_rel + 3;
            let inner_raw = out[after_open..after_open + end_rel].trim();
            let body = if let Some(nl) = inner_raw.find('\n') {
                inner_raw[nl + 1..].trim()
            } else {
                inner_raw
            };
            let key = slot_insert(slots, body.to_string(), true);
            out.replace_range(start..end, &key);
        } else {
            break;
        }
    }
    out
}

fn protect_inline_code(text: &str, slots: &mut Vec<Slot>) -> String {
    let mut out = String::new();
    let mut rest = text;
    while let Some(start) = rest.find('`') {
        out.push_str(&rest[..start]);
        rest = &rest[start + 1..];
        if let Some(end) = rest.find('`') {
            let inner = &rest[..end];
            let key = slot_insert(slots, inner.to_string(), false);
            out.push_str(&key);
            rest = &rest[end + 1..];
        } else {
            out.push('`');
            break;
        }
    }
    out.push_str(rest);
    out
}

fn tag_insert(tags: &mut Vec<String>, value: String) -> String {
    let key = format!("\x01T{}\x01", tags.len());
    tags.push(value);
    key
}

fn apply_tags(text: String, tags: &[String]) -> String {
    let mut out = text;
    for (i, tag) in tags.iter().enumerate() {
        out = out.replace(&format!("\x01T{i}\x01"), tag);
    }
    out
}

fn replace_pairs_tagged(
    text: &str,
    open: &str,
    close: &str,
    tags: &mut Vec<String>,
    wrap: impl Fn(&str) -> String,
    escape_plain: bool,
) -> String {
    let mut out = String::new();
    let mut rest = text;
    while let Some(start) = rest.find(open) {
        push_plain(&mut out, &rest[..start], escape_plain);
        rest = &rest[start + open.len()..];
        if let Some(end) = rest.find(close) {
            let inner = &rest[..end];
            if inner.is_empty() {
                out.push_str(open);
                out.push_str(close);
            } else {
                out.push_str(&tag_insert(tags, wrap(inner)));
            }
            rest = &rest[end + close.len()..];
        } else {
            out.push_str(open);
            break;
        }
    }
    push_plain(&mut out, rest, escape_plain);
    out
}

fn replace_links_tagged(
    text: &str,
    tags: &mut Vec<String>,
    wrap: impl Fn(&str, &str) -> String,
    escape_plain: bool,
) -> String {
    let mut out = String::new();
    let mut rest = text;
    while let Some(start) = rest.find('[') {
        push_plain(&mut out, &rest[..start], escape_plain);
        rest = &rest[start + 1..];
        let title_end = rest.find(']');
        let url_start = rest.find("](");
        if title_end.is_none() || url_start.is_none() || title_end.unwrap() > url_start.unwrap() {
            out.push('[');
            break;
        }
        let title = &rest[..title_end.unwrap()];
        rest = &rest[url_start.unwrap() + 2..];
        let url_end = rest.find(')');
        if url_end.is_none() {
            out.push('[');
            break;
        }
        let url = rest[..url_end.unwrap()].trim();
        out.push_str(&tag_insert(tags, wrap(title, url)));
        rest = &rest[url_end.unwrap() + 1..];
    }
    push_plain(&mut out, rest, escape_plain);
    out
}

fn replace_single_asterisk_tagged(text: &str, tags: &mut Vec<String>, wrap: impl Fn(&str) -> String, escape_plain: bool) -> String {
    let mut out = String::new();
    let mut rest = text;
    while !rest.is_empty() {
        if rest.starts_with("**") {
            out.push_str("**");
            rest = &rest[2..];
            continue;
        }
        if let Some(start) = rest.find('*') {
            push_plain(&mut out, &rest[..start], escape_plain);
            let after = &rest[start + 1..];
            if let Some(end) = after.find('*') {
                let inner = &after[..end];
                if !inner.is_empty() && !inner.contains("**") {
                    out.push_str(&tag_insert(tags, wrap(inner)));
                    rest = &after[end + 1..];
                    continue;
                }
            }
            out.push('*');
            rest = &rest[start + 1..];
            continue;
        }
        push_plain(&mut out, rest, escape_plain);
        break;
    }
    out
}

fn strip_heading_prefix(line: &str) -> &str {
    let trimmed = line.trim_start();
    let hashes = trimmed.chars().take_while(|c| *c == '#').count();
    if hashes == 0 {
        return line;
    }
    trimmed[hashes..].trim_start()
}

fn escape_telegram_html(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

fn push_plain(out: &mut String, text: &str, escape_plain: bool) {
    if escape_plain {
        out.push_str(&escape_telegram_html(text));
    } else {
        out.push_str(text);
    }
}

fn restore_code_slots(text: String, slots: &[Slot], telegram: bool) -> String {
    let mut out = text;
    for slot in slots {
        let rendered = if telegram {
            if slot.fenced {
                format!("<pre>{}</pre>", escape_telegram_html(&slot.value))
            } else {
                format!("<code>{}</code>", escape_telegram_html(&slot.value))
            }
        } else if slot.fenced {
            format!("```{}```", slot.value)
        } else {
            format!("`{}`", slot.value)
        };
        out = out.replace(&slot.key, &rendered);
    }
    out
}

fn markdown_core(text: &str) -> (String, Vec<Slot>) {
    let mut slots = Vec::new();
    let protected = protect_fenced_code(text, &mut slots);
    let protected = protect_inline_code(&protected, &mut slots);
    (protected, slots)
}

fn markdown_inline_telegram_line(line: &str) -> String {
    let mut slots = Vec::new();
    let core = protect_inline_code(line, &mut slots);
    let mut tags = Vec::new();
    let mut text = replace_pairs_tagged(
        &core,
        "**",
        "**",
        &mut tags,
        |s| format!("<b>{}</b>", escape_telegram_html(s)),
        true,
    );
    text = replace_pairs_tagged(&text, "__", "__", &mut tags, |s| format!("<b>{}</b>", escape_telegram_html(s)), false);
    text = replace_pairs_tagged(&text, "~~", "~~", &mut tags, |s| format!("<s>{}</s>", escape_telegram_html(s)), false);
    text = replace_single_asterisk_tagged(&text, &mut tags, |s| format!("<i>{}</i>", escape_telegram_html(s)), false);
    text = replace_pairs_tagged(&text, "_", "_", &mut tags, |s| format!("<i>{}</i>", escape_telegram_html(s)), false);
    text = replace_links_tagged(
        &text,
        &mut tags,
        |title, url| {
            format!(
                "<a href=\"{}\">{}</a>",
                escape_telegram_html(url),
                escape_telegram_html(title)
            )
        },
        false,
    );
    text = apply_tags(text, &tags);
    restore_code_slots(text, &slots, true)
}

fn markdown_inline_whatsapp_line(line: &str) -> String {
    let mut slots = Vec::new();
    let core = protect_inline_code(line, &mut slots);
    let mut tags = Vec::new();
    let mut text = replace_pairs_tagged(&core, "**", "**", &mut tags, |s| format!("*{s}*"), false);
    text = replace_pairs_tagged(&text, "__", "__", &mut tags, |s| format!("*{s}*"), false);
    text = replace_single_asterisk_tagged(&text, &mut tags, |s| format!("_{s}_"), false);
    text = replace_pairs_tagged(&text, "~~", "~~", &mut tags, |s| format!("~{s}~"), false);
    text = replace_pairs_tagged(&text, "_", "_", &mut tags, |s| format!("_{s}_"), false);
    text = replace_links_tagged(
        &text,
        &mut tags,
        |title, url| {
            if title.trim().is_empty() || title == url {
                url.to_string()
            } else {
                format!("{title} ({url})")
            }
        },
        false,
    );
    text = apply_tags(text, &tags);
    restore_code_slots(text, &slots, false)
}

fn format_lines(input: &str, slots: &[Slot], telegram: bool) -> String {
    input
        .lines()
        .map(|line| {
            if line.trim_start().starts_with('#') {
                let title = strip_heading_prefix(line).trim();
                if telegram {
                    format!("<b>{}</b>", escape_telegram_html(title))
                } else {
                    format!("*{title}*")
                }
            } else if slots.iter().any(|s| line.contains(&s.key)) {
                restore_code_slots(line.to_string(), slots, telegram)
            } else if telegram {
                markdown_inline_telegram_line(line)
            } else {
                markdown_inline_whatsapp_line(line)
            }
        })
        .collect::<Vec<_>>()
        .join("\n")
        .trim()
        .to_string()
}

/// Telegram Bot API HTML (`parse_mode: HTML`).
pub fn markdown_to_telegram_html(input: &str) -> String {
    let (core, slots) = markdown_core(input);
    format_lines(&core, &slots, true)
}

/// WhatsApp: *bold*, _italic_, ~strike~, `code`, ```blocks```.
pub fn markdown_to_whatsapp(input: &str) -> String {
    let (core, slots) = markdown_core(input);
    format_lines(&core, &slots, false)
}

pub fn channel_text_format(domain: &str, text: &str) -> String {
    match domain {
        "telegram" => markdown_to_telegram_html(text),
        "whatsapp" => markdown_to_whatsapp(text),
        _ => text.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn telegram_bold_and_italic() {
        let out = markdown_to_telegram_html("Hello **world** and *you*");
        assert!(out.contains("<b>world</b>"));
        assert!(out.contains("<i>you</i>"));
    }

    #[test]
    fn telegram_code_and_link() {
        let out = markdown_to_telegram_html("Use `x` or [site](https://example.com)");
        assert!(out.contains("<code>x</code>"), "got: {out}");
        assert!(out.contains("https://example.com"), "got: {out}");
        assert!(out.contains("site"), "got: {out}");
    }

    #[test]
    fn whatsapp_bold_italic() {
        let out = markdown_to_whatsapp("**bold** and *italic*");
        assert!(out.contains("*bold*"), "got: {out}");
        assert!(out.contains("_italic_"), "got: {out}");
    }

    #[test]
    fn whatsapp_fenced_code() {
        let out = markdown_to_whatsapp("```\nline\n```");
        assert!(out.contains("```line```"));
    }

    #[test]
    fn heading_becomes_bold() {
        assert!(markdown_to_telegram_html("### Title").contains("<b>Title</b>"));
        assert!(markdown_to_whatsapp("### Title").contains("*Title*"));
    }
}
