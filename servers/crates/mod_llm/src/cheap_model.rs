#[cfg(test)]
mod tests {
    use crate::CHEAP_MODEL;

    #[test]
    fn cheap_model_is_gemini_flash_lite() {
        assert_eq!(CHEAP_MODEL, "gemini-3.1-flash-lite");
        assert!(!CHEAP_MODEL.contains("image"));
    }
}
