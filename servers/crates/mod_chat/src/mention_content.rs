// Bracket mentions in chat message text. See _/docs/chat.md (Mention brackets).

pub fn mention_id_from_bracket(kind: &str, body: &str) -> Option<String> {
    let k = kind.trim().to_ascii_lowercase();
    let b = body.trim();
    if b.is_empty() {
        return None;
    }
    match k.as_str() {
        "iid" => Some(format!("iid:{b}")),
        "catalog" => Some(format!("catalog:{b}")),
        "drive" => Some(format!("drive:{b}")),
        _ => None,
    }
}

pub fn mention_bracket_for_id(canonical: &str) -> String {
    let t = canonical.trim();
    if let Some(n) = t.strip_prefix("iid:") {
        return format!("[@iid:{n}]");
    }
    if let Some(n) = t.strip_prefix("catalog:") {
        return format!("[@catalog:{n}]");
    }
    if let Some(n) = t.strip_prefix("drive:") {
        return format!("[@drive:{n}]");
    }
    if t.chars().all(|c| c.is_ascii_digit()) && !t.is_empty() {
        return format!("[@iid:{t}]");
    }
    format!("[@catalog:{t}]")
}

fn plain_iid_replace(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
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

pub fn mention_content_normalize(text: &str, _mention_ids: &[String]) -> String {
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
                    let rep = mention_id_from_bracket(kind, body)
                        .map(|id| mention_bracket_for_id(&id))
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
    plain_iid_replace(&out).trim().to_string()
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
    fn bracket_roundtrip_drive() {
        let id = "drive:reports/q1.csv";
        assert_eq!(mention_bracket_for_id(id), "[@drive:reports/q1.csv]");
        assert_eq!(
            mention_id_from_bracket("drive", "reports/q1.csv").as_deref(),
            Some(id)
        );
    }
}
