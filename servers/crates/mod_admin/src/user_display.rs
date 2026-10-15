/// Staff-facing label for a user without exposing synthetic placeholders.
/// `@{alien_id}` when set; otherwise login email; otherwise empty (omit in UI).
pub fn admin_user_public_handle(alien_id: &str, email: &str) -> String {
    let a = alien_id.trim().trim_start_matches('@');
    if !a.is_empty() {
        return format!("@{a}");
    }
    let e = email.trim();
    if !e.is_empty() {
        return e.to_string();
    }
    String::new()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn handle_prefers_alien_id() {
        assert_eq!(
            admin_user_public_handle("chito", "a@b.com"),
            "@chito"
        );
    }

    #[test]
    fn handle_falls_back_to_email() {
        assert_eq!(admin_user_public_handle("", "a@b.com"), "a@b.com");
        assert_eq!(admin_user_public_handle("  ", "a@b.com"), "a@b.com");
    }

    #[test]
    fn handle_empty_when_both_missing() {
        assert_eq!(admin_user_public_handle("", ""), "");
    }
}
