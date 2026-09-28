pub fn youtube_video_id(input: &str) -> Option<String> {
    let s = input.trim();
    if s.is_empty() {
        return None;
    }
    let lower = s.to_ascii_lowercase();
    if let Some(id) = id_after_marker(s, &lower, "youtu.be/") {
        return Some(id);
    }
    if let Some(id) = id_from_watch(s, &lower) {
        return Some(id);
    }
    if let Some(id) = id_after_marker(s, &lower, "/shorts/") {
        return Some(id);
    }
    if let Some(id) = id_after_marker(s, &lower, "youtube.com/embed/") {
        return Some(id);
    }
    None
}

pub fn youtube_urls_in_text(text: &str) -> Vec<String> {
    let mut out = Vec::new();
    for token in text.split_whitespace() {
        let t = token.trim_matches(|c: char| c == '<' || c == '>' || c == '"' || c == '\'' || c == ')' || c == '(');
        if t.contains("youtube.com") || t.contains("youtu.be") {
            if youtube_video_id(t).is_some() {
                out.push(t.to_string());
            }
        }
    }
    out
}

fn id_from_watch(orig: &str, lower: &str) -> Option<String> {
    let idx = lower.find("v=")?;
    let rest = &orig[idx + 2..];
    let id = rest.split(&['&', '#', '?'][..]).next().unwrap_or("");
    normalize_id(id)
}

fn id_after_marker(orig: &str, lower: &str, marker: &str) -> Option<String> {
    let idx = lower.find(marker)?;
    let rest = &orig[idx + marker.len()..];
    let id = rest.split(&['?', '&', '#', '/'][..]).next().unwrap_or("");
    normalize_id(id)
}

fn normalize_id(id: &str) -> Option<String> {
    let id = id.trim();
    if id.len() == 11 && id.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_') {
        Some(id.to_string())
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_watch_url() {
        assert_eq!(
            youtube_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
            Some("dQw4w9WgXcQ".into())
        );
    }
}