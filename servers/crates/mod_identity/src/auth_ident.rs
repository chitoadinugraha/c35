#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LoginIdent {
    Email(String),
    Phone(String),
    AlienId(String),
}

impl LoginIdent {
    pub fn as_str(&self) -> &str {
        match self {
            Self::Email(s) | Self::Phone(s) | Self::AlienId(s) => s,
        }
    }

    pub fn is_email_or_phone(&self) -> bool {
        matches!(self, Self::Email(_) | Self::Phone(_))
    }
}

pub fn login_ident_parse(raw: &str) -> LoginIdent {
    let s = raw.trim();
    if s.starts_with('@') {
        return LoginIdent::AlienId(s.trim_start_matches('@').to_lowercase());
    }
    if s.contains('@') {
        return LoginIdent::Email(s.to_lowercase());
    }
    // A phone number must not contain letters, and must have at least 8 digits
    let has_letters = s.chars().any(|c| c.is_ascii_alphabetic());
    if !has_letters {
        let digits: String = s.chars().filter(|c| c.is_ascii_digit()).collect();
        if digits.len() >= 8 {
            return LoginIdent::Phone(digits);
        }
    }
    LoginIdent::AlienId(s.to_lowercase())
}

pub fn alien_id_display(alien_id: &str) -> String {
    let a = alien_id.trim().trim_start_matches('@');
    if a.is_empty() {
        "@user".into()
    } else {
        format!("@{a}")
    }
}
