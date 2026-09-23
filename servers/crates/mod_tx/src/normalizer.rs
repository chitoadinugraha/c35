//! Product and object normalization logic.
//! Provides slug normalization and token/abbreviation expansion matching database functions.

use std::collections::HashMap;

/// Normalizes arbitrary raw text into a clean snake_case slug.
/// Matching PostgreSQL ai.slug_norm() implementation:
/// - lowercases all characters
/// - replaces non-alphanumeric sequences with '_'
/// - collapses multiple consecutive underscores into one
/// - trims leading and trailing underscores
pub fn slug_normalize(raw: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return String::new();
    }

    let mut out = String::with_capacity(trimmed.len());
    let mut prev_is_sep = true;

    for c in trimmed.chars() {
        if c.is_ascii_alphanumeric() {
            out.push(c.to_ascii_lowercase());
            prev_is_sep = false;
        } else if !prev_is_sep {
            out.push('_');
            prev_is_sep = true;
        }
    }

    if out.ends_with('_') {
        out.pop();
    }
    out
}

/// Expands known abbreviations in tokens using the word dictionary.
/// E.g. ["nasi", "grg", "aym"] with {"grg": "goreng", "aym": "ayam"} -> ["nasi", "goreng", "ayam"]
pub fn word_expand_tokens(tokens: &[&str], dict: &HashMap<String, String>) -> Vec<String> {
    tokens
        .iter()
        .map(|t| {
            let lower = t.to_ascii_lowercase();
            dict.get(&lower).cloned().unwrap_or(lower)
        })
        .collect()
}

/// Tokenizes raw string and expands abbreviations using word dictionary, returning a normalized slug.
pub fn text_normalize_with_dict(raw: &str, dict: &HashMap<String, String>) -> String {
    let tokens: Vec<&str> = raw
        .split(|c: char| !c.is_alphanumeric())
        .filter(|s| !s.is_empty())
        .collect();
    let expanded = word_expand_tokens(&tokens, dict);
    slug_normalize(&expanded.join(" "))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_slug_normalize_variations() {
        assert_eq!(slug_normalize("INDOMIE-GORENG"), "indomie_goreng");
        assert_eq!(slug_normalize("indomie goreng"), "indomie_goreng");
        assert_eq!(slug_normalize("Indomie   Goreng!"), "indomie_goreng");
        assert_eq!(slug_normalize("  --indomie_goreng--  "), "indomie_goreng");
        assert_eq!(slug_normalize(""), "");
    }

    #[test]
    fn test_word_expand_and_slug() {
        let mut dict = HashMap::new();
        dict.insert("grg".to_string(), "goreng".to_string());
        dict.insert("aym".to_string(), "ayam".to_string());
        dict.insert("bkr".to_string(), "bakar".to_string());

        let res = text_normalize_with_dict("NASI GRG AYM BKR", &dict);
        assert_eq!(res, "nasi_goreng_ayam_bakar");

        let res2 = text_normalize_with_dict("indomie grg", &dict);
        assert_eq!(res2, "indomie_goreng");
    }
}
