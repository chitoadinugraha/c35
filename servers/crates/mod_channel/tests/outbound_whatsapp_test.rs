use std::sync::{Arc, Mutex};
use std::time::Duration;

use axum::{routing::any, Json, Router};
use c35_mod_channel::outbound::{channel_reply, outbound_ctx_from_channel};
use c35_mod_channel::store::ChannelDoc;

static WA_ENV_MUTEX: Mutex<()> = Mutex::new(());

#[tokio::test]
async fn whatsapp_outbound_send_text_chunks() {
    let _lock = WA_ENV_MUTEX.lock().unwrap();
    let calls = Arc::new(Mutex::new(Vec::<(String, String)>::new()));
    let c = calls.clone();
    let app = Router::new().fallback(any(move |uri: axum::http::Uri, body: axum::body::Bytes| {
        let c = c.clone();
        async move {
            c.lock().unwrap().push((uri.to_string(), String::from_utf8_lossy(&body).to_string()));
            Json(serde_json::json!({ "messages": [{ "id": "wamid.123" }] }))
        }
    }));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    tokio::time::sleep(Duration::from_millis(50)).await;
    std::env::set_var("META_GRAPH_API_BASE", format!("http://{addr}"));

    let client = reqwest::Client::new();
    let ctx = outbound_ctx_from_channel(
        "whatsapp",
        "628123456789@s.whatsapp.net",
        &ChannelDoc {
            id: "ch_wa".into(),
            platform: "whatsapp".into(),
            provider: "meta_api".into(),
            status: "connected".into(),
            webhook_secret: String::new(),
            verify_token: "verify123".into(),
            bot_token: String::new(),
            bot_username: String::new(),
            phone_number_id: "phone_123".into(),
            access_token: "token_abc".into(),
            phone: "+628123456789".into(),
            error_message: String::new(),
            session: c35_mod_channel::store::ChannelSession::default(),
        },
    );

    let long_msg = "WhatsApp repeating line.\n".repeat(300);
    channel_reply(&client, &ctx, &long_msg, false).await.unwrap();

    let recorded = calls.lock().unwrap().clone();
    assert!(recorded.len() > 1, "Expected multiple chunked calls, got {}", recorded.len());
    for (path, body) in recorded {
        assert!(path.contains("/phone_123/messages"));
        let v: serde_json::Value = serde_json::from_str(&body).unwrap();
        assert_eq!(v["messaging_product"], "whatsapp");
        assert_eq!(v["to"], "628123456789");
        let text = v["text"]["body"].as_str().unwrap();
        assert!(text.chars().count() <= c35_mod_channel::outbound::TG_TEXT_MAX);
    }
}

#[tokio::test]
async fn whatsapp_outbound_send_audio_voice() {
    let _lock = WA_ENV_MUTEX.lock().unwrap();
    let calls = Arc::new(Mutex::new(Vec::<(String, String)>::new()));
    let c = calls.clone();
    let app = Router::new().fallback(any(move |uri: axum::http::Uri, body: axum::body::Bytes| {
        let c = c.clone();
        async move {
            let path = uri.to_string();
            c.lock().unwrap().push((path.clone(), String::from_utf8_lossy(&body).to_string()));
            if path.contains("/media") {
                Json(serde_json::json!({ "id": "media_uploaded_999" }))
            } else {
                Json(serde_json::json!({ "messages": [{ "id": "wamid.voice999" }] }))
            }
        }
    }));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    tokio::time::sleep(Duration::from_millis(50)).await;

    let client = reqwest::Client::new();
    std::env::set_var("META_GRAPH_API_BASE", format!("http://{addr}"));

    let fake_audio = b"ID3fake_mp3_audio_bytes";
    let res = c35_mod_channel::whatsapp::wa_cloud_send_audio(
        &client,
        "phone_123",
        "token_abc",
        "628123456789",
        fake_audio,
        "audio/mpeg",
        false,
    )
    .await;
    assert!(res.is_ok());

    let recorded = calls.lock().unwrap().clone();
    assert_eq!(recorded.len(), 2, "Expected /media upload followed by /messages");
    assert!(recorded[0].0.contains("/phone_123/media"));
    assert!(recorded[1].0.contains("/phone_123/messages"));
    let v: serde_json::Value = serde_json::from_str(&recorded[1].1).unwrap();
    assert_eq!(v["type"], "audio");
    assert_eq!(v["audio"]["id"], "media_uploaded_999");
}
