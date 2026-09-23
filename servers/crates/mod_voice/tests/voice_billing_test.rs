use c35_mod_billing::{RETAIL_MARKUP, VOICE_STT_USD_PER_MIN, VOICE_TTS_USD_PER_1K_CHARS};
use c35_mod_voice::{
    estimate_stt_cost_usd, estimate_stt_duration, estimate_tts_cost_usd, voice_billing_abort,
    voice_req_id, voice_stt_wholesale_usd, voice_tts_wholesale_usd,
};

fn fake_wav(payload_bytes: usize) -> Vec<u8> {
    let mut wav = vec![0u8; 44 + payload_bytes];
    wav[..4].copy_from_slice(b"RIFF");
    wav[8..12].copy_from_slice(b"WAVE");
    wav[24..28].copy_from_slice(&16_000u32.to_le_bytes());
    wav
}

#[test]
fn voice_req_id_adds_prefix() {
    assert_eq!(voice_req_id("voice_stt_", "abc"), "voice_stt_abc");
    assert_eq!(voice_req_id("voice_stt_", "voice_stt_abc"), "voice_stt_abc");
    assert_eq!(voice_req_id("voice_tts_", "x"), "voice_tts_x");
}

#[test]
fn estimate_stt_duration_wav_16k_mono() {
    let wav = fake_wav(32_000);
    let secs = estimate_stt_duration(&wav, "audio/wav");
    assert!((secs - 1.0).abs() < 0.05);
}

#[test]
fn estimate_stt_cost_scales_with_duration() {
    let one_min = estimate_stt_cost_usd(&fake_wav(32_000 * 60), "audio/wav");
    let half_min = estimate_stt_cost_usd(&fake_wav(32_000 * 30), "audio/wav");
    assert!((one_min - VOICE_STT_USD_PER_MIN).abs() < 0.001);
    assert!((half_min - VOICE_STT_USD_PER_MIN / 2.0).abs() < 0.001);
}

#[test]
fn estimate_tts_cost_scales_with_chars() {
    let text = "a".repeat(2_000);
    let cost = estimate_tts_cost_usd(&text);
    assert!((cost - VOICE_TTS_USD_PER_1K_CHARS * 2.0).abs() < 0.0001);
    assert_eq!(estimate_tts_cost_usd(""), 0.0);
}

#[test]
fn wholesale_is_retail_divided_by_markup() {
    let audio = fake_wav(32_000 * 60);
    let retail = estimate_stt_cost_usd(&audio, "audio/wav");
    let wholesale = voice_stt_wholesale_usd(&audio, "audio/wav");
    assert!((wholesale * RETAIL_MARKUP - retail).abs() < 0.0001);

    let text = "hello world";
    let retail_tts = estimate_tts_cost_usd(text);
    let wholesale_tts = voice_tts_wholesale_usd(text);
    assert!((wholesale_tts * RETAIL_MARKUP - retail_tts).abs() < 0.0001);
}

#[tokio::test]
async fn voice_billing_abort_empty_req_id_is_noop() {
    // Refund path should not error on empty req_id (matches billing_reservation_refund).
    voice_billing_abort(&sqlx::PgPool::connect_lazy("postgres://invalid").unwrap(), "").await.unwrap();
}
