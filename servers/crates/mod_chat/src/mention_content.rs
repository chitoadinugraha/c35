// Bracket mentions in chat message text. See _/specs/mention.md (Mention brackets).

/// Split optional display snapshot after `|`. Payload must not contain `]`.
pub fn mention_bracket_body_parts(body: &str) -> (&str, Option<&str>) {
    let b = body.trim();
    let Some(idx) = b.find('|') else {
        return (b, None);
    };
    let payload = b[..idx].trim();
    let label = b[idx + 1..].trim();
    if payload.is_empty() {
        return (b, None);
    }
    if label.is_empty() {
        return (payload, None);
    }
    (payload, Some(label))
}

pub fn mention_id_from_bracket(kind: &str, body: &str) -> Option<String> {
    let k = kind.trim().to_ascii_lowercase();
    let (payload, _) = mention_bracket_body_parts(body);
    if payload.is_empty() {
        return None;
    }
    match k.as_str() {
        "iid" => Some(format!("iid:{payload}")),
        "catalog" => Some(format!("catalog:{payload}")),
        "drive" => Some(format!("drive:{payload}")),
        _ => None,
    }
}

fn mention_bracket_label_safe(label: &str) -> bool {
    let t = label.trim();
    !t.is_empty() && !t.contains(']')
}

pub fn mention_bracket_for_id_with_label(canonical: &str, label: Option<&str>) -> String {
    let base = mention_bracket_for_id(canonical);
    if base.contains('|') {
        return base;
    }
    let Some(l) = label.map(str::trim).filter(|s| mention_bracket_label_safe(s)) else {
        return base;
    };
    if base.ends_with(']') {
        let inner = base.trim_start_matches('[').trim_end_matches(']');
        return format!("[{inner}|{l}]");
    }
    base
}

pub fn mention_bracket_for_id(canonical: &str) -> String {
    let t = canonical.trim();
    if t.starts_with("[@") {
        if let Some(end) = t.find(']') {
            let inner = &t[2..end];
            if let Some(colon) = inner.find(':') {
                let kind = &inner[..colon];
                let body = &inner[colon + 1..];
                if let Some(id) = mention_id_from_bracket(kind, body) {
                    return mention_bracket_for_id(&id);
                }
            }
        }
    }
    if let Some(n) = t.strip_prefix("iid:") {
        let (payload, _) = mention_bracket_body_parts(n);
        return format!("[@iid:{payload}]");
    }
    if let Some(n) = t.strip_prefix("catalog:") {
        let (payload, _) = mention_bracket_body_parts(n);
        return format!("[@catalog:{payload}]");
    }
    if let Some(n) = t.strip_prefix("drive:") {
        let (payload, _) = mention_bracket_body_parts(n);
        return format!("[@drive:{payload}]");
    }
    if t.chars().all(|c| c.is_ascii_digit()) && !t.is_empty() {
        return format!("[@iid:{t}]");
    }
    format!("[@catalog:{t}]")
}

fn inside_bracket_mention_at(text: &str, i: usize) -> bool {
    let before = &text[..i];
    let Some(open) = before.rfind("[@") else {
        return false;
    };
    !before[open..].contains(']')
}

fn plain_iid_replace(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if inside_bracket_mention_at(text, i) {
            out.push(bytes[i] as char);
            i += 1;
            continue;
        }
        if i + 4 < bytes.len()
            && (bytes[i] == b'i' || bytes[i] == b'I')
            && (bytes[i + 1] == b'i' || bytes[i + 1] == b'I')
            && (bytes[i + 2] == b'd' || bytes[i + 2] == b'D')
            && bytes[i + 3] == b':'
        {
            let word_start = i == 0 || !bytes[i - 1].is_ascii_alphanumeric();
            let mut j = i + 4;
            while j < bytes.len() && bytes[j].is_ascii_digit() {
                j += 1;
            }
            let word_end = j >= bytes.len() || !bytes[j].is_ascii_alphanumeric();
            if word_start && word_end && j > i + 4 {
                let n = &text[i + 4..j];
                out.push_str(&mention_bracket_for_id(&format!("iid:{n}")));
                i = j;
                continue;
            }
        }
        out.push(bytes[i] as char);
        i += 1;
    }
    out
}

fn is_letter(c: char) -> bool {
    c.is_ascii_alphabetic()
}

fn mention_bracket_close_before_letter(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 8);
    let bytes = s.as_bytes();
    let mut i = 0usize;
    while i < bytes.len() {
        if s[i..].starts_with("[@iid:") {
            let start = i;
            i += 6;
            while i < bytes.len() && bytes[i].is_ascii_digit() {
                i += 1;
            }
            if i < bytes.len() && bytes[i] == b'|' {
                i += 1;
                while i < bytes.len() && bytes[i] != b']' && bytes[i] != b'[' {
                    i += 1;
                }
            }
            if i < bytes.len() && bytes[i] == b']' {
                out.push_str(&s[start..=i]);
                i += 1;
                continue;
            }
            if i < bytes.len() && is_letter(s[i..].chars().next().unwrap_or('\0')) {
                out.push_str(&s[start..i]);
                out.push_str("] ");
                continue;
            }
            out.push_str(&s[start..i]);
            continue;
        }
        if s[i..].starts_with("[@catalog:") || s[i..].starts_with("[@drive:") {
            if let Some(colon) = s[i..].find(':') {
                let start = i;
                i += colon + 1;
                while i < bytes.len() && bytes[i] != b']' && bytes[i] != b'[' {
                    i += 1;
                }
                if i < bytes.len() && bytes[i] == b']' {
                    out.push_str(&s[start..=i]);
                    i += 1;
                    continue;
                }
                if i < bytes.len() && is_letter(s[i..].chars().next().unwrap_or('\0')) {
                    out.push_str(&s[start..i]);
                    out.push_str("] ");
                    continue;
                }
                out.push_str(&s[start..i]);
                continue;
            }
        }
        if bytes[i] == b']' && i + 1 < bytes.len() {
            let next = s[i + 1..].chars().next();
            if next.is_some_and(is_letter) {
                out.push(']');
                out.push(' ');
                i += 1;
                continue;
            }
        }
        let ch = s[i..].chars().next().unwrap();
        out.push(ch);
        i += ch.len_utf8();
    }
    out
}

pub fn mention_bracket_repair(text: &str) -> String {
    let mut s = mention_bracket_close_before_letter(text);
    if let Some(pos) = s.rfind("[@") {
        if !s[pos..].contains(']') {
            s = s[..pos].trim_end().to_string();
        }
    }
    s
}

pub fn mention_bracket_fixup_nesting(text: &str) -> String {
    let mut s = text.to_string();
    for _ in 0..8 {
        let prev = s.clone();
        while s.contains("[@[@") {
            s = s.replacen("[@[@", "[@", 1);
        }
        while s.contains("[@@[") {
            s = s.replacen("[@@[", "[@[", 1);
        }
        if s.starts_with("[@") && !s.starts_with("[@iid:") && !s.starts_with("[@catalog:") && !s.starts_with("[@drive:") {
            let idx = ["[@iid:", "[@catalog:", "[@drive:"]
                .iter()
                .filter_map(|p| s.find(p))
                .min()
                .unwrap_or(0);
            if idx > 0 {
                s = s[idx..].to_string();
            }
        }
        while let Some(pos) = s.find("[@iid:") {
            let tail = &s[pos..];
            let Some(r) = tail.find(']') else { break };
            let after = pos + r + 1;
            if after < s.len() && s.as_bytes()[after] == b']' {
                s.remove(after);
                continue;
            }
            break;
        }
        if s == prev {
            break;
        }
    }
    s
}

/// Strip bracket mentions for inbox titles (device names applied separately when known).
pub fn mention_plain_for_title(text: &str) -> String {
    let mut s = mention_bracket_fixup_nesting(text);
    for _ in 0..16 {
        let Some(start) = s.find("[@") else {
            break;
        };
        let tail = &s[start..];
        let Some(rel) = tail.find(']') else {
            break;
        };
        let end = start + rel;
        let before = s[..start].trim_end();
        let after = s[end + 1..].trim_start();
        s = if before.is_empty() {
            after.to_string()
        } else if after.is_empty() {
            before.to_string()
        } else {
            format!("{before} {after}")
        };
    }
    s.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Ensure each `[@…]` in text has a `|label` snapshot when [labels] supplies one for that id.
pub fn mention_brackets_attach_labels(text: &str, labels: &[(String, String)]) -> String {
    let mut s = mention_bracket_fixup_nesting(text);
    for (id, label) in labels {
        let plain = mention_bracket_for_id(id);
        let labeled = mention_bracket_for_id_with_label(id, Some(label));
        if plain == labeled || s.contains(&labeled) || !s.contains(&plain) {
            continue;
        }
        if let Some(pos) = s.find(&plain) {
            s.replace_range(pos..pos + plain.len(), &labeled);
        }
    }
    s
}

pub const CHAT_TITLE_MAX_CHARS: usize = 80;

pub fn chat_title_from_bracket_text(text: &str) -> String {
    let raw: String = truncate_title_preserving_brackets(text.trim(), CHAT_TITLE_MAX_CHARS);
    if raw.is_empty() {
        return "Chat".into();
    }
    capitalize_first_letter_char(&raw)
}

fn truncate_title_preserving_brackets(text: &str, max_chars: usize) -> String {
    if text.is_empty() {
        return String::new();
    }
    let mut out = String::new();
    let mut count = 0usize;
    let mut i = 0usize;
    let bytes = text.as_bytes();
    while i < bytes.len() && count < max_chars {
        if bytes[i] == b'[' && i + 1 < bytes.len() && bytes[i + 1] == b'@' {
            let mut j = i + 2;
            while j < bytes.len() && bytes[j] != b']' {
                j += 1;
            }
            if j < bytes.len() {
                let token = &text[i..=j];
                let token_len = token.chars().count();
                if count + token_len > max_chars {
                    i = j + 1;
                    continue;
                }
                out.push_str(token);
                count += token_len;
                i = j + 1;
                continue;
            }
        }
        let ch = text[i..].chars().next().unwrap();
        out.push(ch);
        count += 1;
        i += ch.len_utf8();
    }
    out.trim().to_string()
}

fn capitalize_first_letter_char(s: &str) -> String {
    let mut i = 0usize;
    while i < s.len() {
        if s[i..].starts_with("[@") {
            if let Some(rel) = s[i..].find(']') {
                i += rel + 1;
                continue;
            }
            break;
        }
        let c = s[i..].chars().next().unwrap();
        if c.is_alphabetic() {
            let mut out = String::with_capacity(s.len());
            out.extend(s[..i].chars());
            out.extend(c.to_uppercase());
            out.extend(s[i + c.len_utf8()..].chars());
            return out;
        }
        i += c.len_utf8();
    }
    s.to_string()
}

pub fn mention_content_normalize(text: &str, _mention_ids: &[String]) -> String {
    let text = mention_bracket_repair(text);
    let text = mention_bracket_fixup_nesting(&text);
    let mut out = String::new();
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'[' && i + 1 < bytes.len() && bytes[i + 1] == b'@' {
            let start = i + 2;
            let mut j = start;
            while j < bytes.len() && bytes[j] != b':' {
                j += 1;
            }
            if j < bytes.len() {
                let kind = &text[start..j];
                let val_start = j + 1;
                let mut k = val_start;
                while k < bytes.len() && bytes[k] != b']' {
                    k += 1;
                }
                if k < bytes.len() {
                    let body = &text[val_start..k];
                    let (_, snap) = mention_bracket_body_parts(body);
                    let rep = mention_id_from_bracket(kind, body)
                        .map(|id| mention_bracket_for_id_with_label(&id, snap))
                        .unwrap_or_else(|| text[i..=k].to_string());
                    out.push_str(&rep);
                    i = k + 1;
                    continue;
                }
            }
        }
        out.push(bytes[i] as char);
        i += 1;
    }
    let trimmed = plain_iid_replace(&out).trim().to_string();
    mention_bracket_fixup_nesting(&trimmed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bracket_roundtrip_iid() {
        let id = "iid:97279816209936384";
        assert_eq!(mention_bracket_for_id(id), "[@iid:97279816209936384]");
        assert_eq!(
            mention_id_from_bracket("iid", "97279816209936384").as_deref(),
            Some(id)
        );
    }

    #[test]
    fn normalize_plain_iid_in_sentence() {
        let out = mention_content_normalize("ping iid:42 ke google", &[]);
        assert!(out.contains("[@iid:42]"));
        assert!(!out.contains(" ping iid:42"));
    }

    #[test]
    fn normalize_collapses_nested_device_bracket() {
        let raw = "[@[@iid:98063412749627392]]tambahkan 5 baris contoh";
        let out = mention_content_normalize(raw, &[]);
        assert!(
            out.starts_with("[@iid:98063412749627392]"),
            "got: {out}"
        );
        assert!(!out.contains("[@["), "got: {out}");
    }

    #[test]
    fn fixup_collapses_nested_device_brackets() {
        let out = mention_bracket_fixup_nesting("[@@[@[@iid:98348080882880512]]] tab list");
        assert!(out.starts_with("[@iid:98348080882880512]"), "got: {out}");
        assert!(!out.contains("[@["), "got: {out}");
    }

    #[test]
    fn plain_for_title_strips_brackets() {
        let out = mention_plain_for_title("[@iid:42] buka chrome");
        assert_eq!(out, "buka chrome");
        let nested = mention_plain_for_title("[@[@iid:42]] buka chrome");
        assert_eq!(nested, "buka chrome");
    }

    #[test]
    fn bracket_repair_closes_before_message_text() {
        let raw = "[@iid:42what is on screen";
        let out = mention_bracket_repair(raw);
        assert!(out.starts_with("[@iid:42]"), "got: {out}");
        assert!(out.contains("what is on screen"), "got: {out}");
    }

    #[test]
    fn plain_iid_skips_inside_labeled_bracket() {
        let raw = "[@iid:42|VM1] change A3";
        let out = mention_content_normalize(raw, &[]);
        assert_eq!(out, raw, "got: {out}");
    }

    #[test]
    fn attach_labels_idempotent() {
        let id = "iid:42".to_string();
        let labeled = mention_bracket_for_id_with_label(&id, Some("VM1"));
        let once = mention_brackets_attach_labels(&labeled, &[(id.clone(), "VM1".into())]);
        assert_eq!(once, "[@iid:42|VM1]");
        let twice = mention_brackets_attach_labels(&once, &[(id.clone(), "VM1".into())]);
        assert_eq!(twice, "[@iid:42|VM1]");
    }

    #[test]
    fn bracket_label_roundtrip() {
        let id = "iid:42";
        assert_eq!(
            mention_bracket_for_id_with_label(id, Some("VM1")),
            "[@iid:42|VM1]"
        );
        assert_eq!(
            mention_id_from_bracket("iid", "42|VM1").as_deref(),
            Some(id)
        );
    }

    #[test]
    fn chat_title_keeps_labeled_bracket() {
        let out = chat_title_from_bracket_text("[@iid:42|VM1] can you add rows");
        assert!(out.starts_with("[@iid:42|VM1]"), "got: {out}");
        assert!(out.contains("Can you"), "got: {out}");
    }

    #[test]
    fn bracket_roundtrip_drive() {
        let id = "drive:reports/q1.csv";
        assert_eq!(mention_bracket_for_id(id), "[@drive:reports/q1.csv]");
        assert_eq!(
            mention_id_from_bracket("drive", "reports/q1.csv").as_deref(),
            Some(id)
        );
    }
}
