pub fn thought_strip(content: &str) -> String {
    let trimmed = content.trim_start();
    let Some(rest) = trimmed.strip_prefix("<thought>") else {
        return content.to_string();
    };
    let Some(end) = rest.find("</thought>") else {
        return content.to_string();
    };
    let answer = rest[end + "</thought>".len()..].trim_start();
    if answer.is_empty() {
        content.to_string()
    } else {
        answer.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_thought_tags() {
        assert_eq!(
            thought_strip("<thought>plan</thought>\nVisible"),
            "Visible"
        );
    }
}
