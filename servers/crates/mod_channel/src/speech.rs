use anyhow::{anyhow, Context, Result};
use reqwest::Client;
use tracing::warn;

/// Strip markdown / URLs / thoughts for TTS and channel voice captions.
pub fn speech_text_clean(raw: &str) -> String {
    let mut text = raw.to_string();
    while let Some(start) = text.find("```") {
        if let Some(end) = text[start + 3..].find("```") {
            text.replace_range(start..start + 3 + end + 3, " ");
        } else {
            text.replace_range(start.., " ");
            break;
        }
    }
    while let Some(start) = text.find("<thought>") {
        if let Some(end) = text[start..].find("</thought>") {
            text.replace_range(start..start + end + "</thought>".len(), " ");
        } else {
            text.replace_range(start.., " ");
            break;
        }
    }
    while let Some(start) = text.find('<') {
        if let Some(end) = text[start..].find('>') {
            let tag = &text[start..start + end + 1];
            if tag.starts_with("<thought>") || tag.starts_with("</thought>") {
                text.replace_range(start..start + end + 1, " ");
            } else {
                break;
            }
        } else {
            break;
        }
    }
    text = text
        .split_whitespace()
        .filter(|word| !word.starts_with("http://") && !word.starts_with("https://"))
        .collect::<Vec<_>>()
        .join(" ");
    for ch in ['*', '_', '~', '`', '#'] {
        text = text.replace(ch, " ");
    }
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

pub fn speech_text_cap(text: &str, max_sentences: usize) -> String {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return String::new();
    }
    let mut parts = Vec::new();
    let mut start = 0usize;
    for (i, ch) in trimmed.char_indices() {
        if matches!(ch, '.' | '!' | '?') {
            let end = i + ch.len_utf8();
            let segment = trimmed[start..end].trim();
            if !segment.is_empty() {
                parts.push(segment.to_string());
            }
            start = end;
            while start < trimmed.len() {
                let rest = trimmed[start..].trim_start();
                start = trimmed.len() - rest.len();
                break;
            }
        }
    }
    if start < trimmed.len() {
        let tail = trimmed[start..].trim();
        if !tail.is_empty() {
            parts.push(tail.to_string());
        }
    }
    if parts.len() <= max_sentences {
        return trimmed.to_string();
    }
    parts.into_iter().take(max_sentences).collect::<Vec<_>>().join(" ")
}

const ID_HINTS: &[&str] = &[
    "yang", "dan", "ini", "itu", "dengan", "untuk", "tidak", "bisa", "ada", "kamu", "kita", "apa", "atau", "dari",
    "sudah", "akan", "saya", "aku", "karena", "jadi", "mau", "juga", "kalau", "sekarang", "mungkin", "ingin",
    "adalah", "pada", "dalam", "oleh", "sebagai", "bagi", "tentang", "seperti", "antara", "secara", "tanpa",
    "hingga", "sampai", "terhadap", "kepada", "namun", "tetapi", "tapi", "sedangkan", "melainkan", "sehingga",
    "supaya", "agar", "meskipun", "walaupun", "serta", "sambil", "bahkan", "lagi", "pun", "nya", "di", "ke",
];

const EN_HINTS: &[&str] = &[
    "the", "and", "is", "are", "was", "were", "have", "has", "had", "will", "would", "could", "should", "this",
    "that", "with", "from", "they", "them", "their", "there", "what", "when", "where", "which", "who", "whom",
    "your", "you", "our", "we", "my", "me", "i", "a", "an", "to", "of", "in", "on", "at", "for", "not", "but",
    "or", "if", "then", "than", "so", "as", "by", "about", "into", "through", "during", "before", "after",
];

pub fn speech_lang_tts_code(text: &str) -> &'static str {
    let lower = text.to_lowercase();
    let words: Vec<&str> = lower
        .split(|c: char| !c.is_ascii_alphabetic())
        .filter(|w| !w.is_empty())
        .collect();
    let id_hits = words.iter().filter(|w| ID_HINTS.contains(w)).count();
    let en_hits = words.iter().filter(|w| EN_HINTS.contains(w)).count();
    if id_hits > en_hits { "id" } else { "en" }
}

pub async fn web_tts(client: &Client, text: &str, lang: &str) -> Result<Vec<u8>> {
    let spoken = speech_text_cap(text, 2);
    if spoken.trim().is_empty() {
        return Err(anyhow!("empty tts text"));
    }
    let url = format!(
        "https://translate.google.com/translate_tts?ie=UTF-8&tl={lang}&client=tw-ob&q={}",
        urlencoding::encode(&spoken)
    );
    let res = client
        .get(&url)
        .header(
            "User-Agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
        )
        .send()
        .await
        .context("web tts request")?;
    if !res.status().is_success() {
        return Err(anyhow!("web tts status {}", res.status()));
    }
    let bytes = res.bytes().await.context("web tts body")?;
    if bytes.is_empty() {
        return Err(anyhow!("web tts empty body"));
    }
    Ok(bytes.to_vec())
}

pub fn is_ogg_audio(mime: &str, bytes: &[u8]) -> bool {
    let m = mime.to_lowercase();
    if m.contains("ogg") || m.contains("opus") {
        return true;
    }
    bytes.len() >= 4 && bytes[..4] == *b"OggS"
}

pub async fn web_tts_logged(client: &Client, text: &str, lang: &str) -> Option<Vec<u8>> {
    match web_tts(client, text, lang).await {
        Ok(v) => Some(v),
        Err(e) => {
            warn!("[c35:channel] web tts failed: {e:#}");
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn clean_strips_backticks_and_thoughts() {
        let clean = speech_text_clean("<thought>private</thought>Hello `code` **world**");
        assert!(!clean.contains('`'));
        assert!(!clean.contains("private"));
        assert_eq!(clean, "Hello code world");
    }

    #[test]
    fn cap_limits_sentences() {
        let capped = speech_text_cap("One. Two. Three.", 2);
        assert_eq!(capped, "One. Two.");
    }

    #[test]
    fn lang_detect_id_and_en() {
        assert_eq!(speech_lang_tts_code("halo saya mau tanya sesuatu"), "id");
        assert_eq!(speech_lang_tts_code("hello how can i help you today"), "en");
    }

    #[test]
    fn is_ogg_audio_detects_mime_and_magic() {
        assert!(is_ogg_audio("audio/ogg", b""));
        assert!(is_ogg_audio("application/octet-stream", b"OggS\x00"));
        assert!(!is_ogg_audio("audio/mpeg", b"ID3"));
    }
}
