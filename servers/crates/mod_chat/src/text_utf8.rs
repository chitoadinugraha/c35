//! UTF-8 safe truncation — avoids panics from `str[..n]` or `String::truncate` on non-char boundaries.

/// Truncate to at most `max_bytes` UTF-8 bytes on a char boundary; append `suffix` when shortened.
pub fn truncate_utf8_bytes(s: &str, max_bytes: usize, suffix: &str) -> String {
    if s.len() <= max_bytes {
        return s.to_string();
    }
    let mut end = max_bytes.min(s.len());
    while end > 0 && !s.is_char_boundary(end) {
        end -= 1;
    }
    if end == 0 {
        return suffix.to_string();
    }
    format!("{}{}", &s[..end], suffix)
}

/// Truncate to at most `max_chars` Unicode scalars; append `suffix` when shortened.
#[allow(dead_code)]
pub fn truncate_utf8_chars(s: &str, max_chars: usize, suffix: &str) -> String {
    let count = s.chars().count();
    if count <= max_chars {
        return s.to_string();
    }
    let clipped: String = s.chars().take(max_chars).collect();
    format!("{}{}", clipped, suffix)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn truncate_bytes_on_em_dash_boundary() {
        let mut s = "a".repeat(7997);
        s.push('\u{2014}');
        s.push_str("tail");
        assert!(s.len() > 8000);
        let out = truncate_utf8_bytes(&s, 8000, "\u{2026}");
        assert!(out.ends_with('\u{2026}'));
        assert!(out.is_char_boundary(out.len()));
    }

    #[test]
    fn truncate_bytes_at_299_does_not_panic() {
        let mut s = "a".repeat(297);
        s.push('\u{2014}');
        s.push('z');
        let out = truncate_utf8_bytes(&s, 299, "");
        assert!(!out.is_empty());
    }

    #[test]
    fn truncate_chars_on_em_dash() {
        let s = "ab\u{2014}cd";
        let out = truncate_utf8_chars(s, 3, "!");
        assert_eq!(out, "ab\u{2014}!");
    }
}
