use std::sync::{Arc, Mutex};
use std::time::Duration;

use axum::{routing::any, Json, Router};
use c35_mod_channel::outbound::{channel_reply, outbound_ctx_from_channel};
use c35_mod_channel::store::ChannelDoc;

static ENV_MUTEX: Mutex<()> = Mutex::new(());

#[tokio::test]
async fn telegram_outbound_send_message() {
    let _lock = ENV_MUTEX.lock().unwrap();
    let captured = Arc::new(Mutex::new(None::<(String, String)>));
    let cap = captured.clone();
    let app = Router::new().fallback(any(move |uri: axum::http::Uri, body: axum::body::Bytes| {
        let cap = cap.clone();
        async move {
            *cap.lock().unwrap() = Some((uri.to_string(), String::from_utf8_lossy(&body).to_string()));
            Json(serde_json::json!({ "ok": true, "result": {} }))
        }
    }));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    tokio::time::sleep(Duration::from_millis(50)).await;
    std::env::set_var("TELEGRAM_API_BASE", format!("http://{addr}"));

    let client = reqwest::Client::new();
    let ctx = outbound_ctx_from_channel(
        "telegram",
        "881234567",
        &ChannelDoc {
            id: "ch1".into(),
            platform: "telegram".into(),
            provider: String::new(),
            status: "connected".into(),
            webhook_secret: String::new(),
            verify_token: String::new(),
            bot_token: "123:OUT".into(),
            bot_username: "out_bot".into(),
            phone_number_id: String::new(),
            access_token: String::new(),
            phone: String::new(),
            error_message: String::new(),
            session: c35_mod_channel::store::ChannelSession::default(),
        },
    );
    channel_reply(&client, &ctx, "hello telegram", false).await.unwrap(); // cas=None via channel_reply

    let (path, body) = captured.lock().unwrap().clone().expect("telegram sendMessage should be called");
    assert!(path.contains("/sendMessage"));
    let v: serde_json::Value = serde_json::from_str(&body).unwrap();
    assert_eq!(v["chat_id"], "881234567");
    assert_eq!(v["text"], "hello telegram");
}

#[tokio::test]
async fn telegram_outbound_splits_long_message() {
    let _lock = ENV_MUTEX.lock().unwrap();
    let calls = Arc::new(Mutex::new(Vec::<(String, String)>::new()));
    let c = calls.clone();
    let app = Router::new().fallback(any(move |uri: axum::http::Uri, body: axum::body::Bytes| {
        let c = c.clone();
        async move {
            c.lock().unwrap().push((uri.to_string(), String::from_utf8_lossy(&body).to_string()));
            Json(serde_json::json!({ "ok": true, "result": {} }))
        }
    }));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    tokio::time::sleep(Duration::from_millis(50)).await;
    std::env::set_var("TELEGRAM_API_BASE", format!("http://{addr}"));

    let client = reqwest::Client::new();
    let ctx = outbound_ctx_from_channel(
        "telegram",
        "881234567",
        &ChannelDoc {
            id: "ch1".into(),
            platform: "telegram".into(),
            provider: String::new(),
            status: "connected".into(),
            webhook_secret: String::new(),
            verify_token: String::new(),
            bot_token: "123:OUT".into(),
            bot_username: "out_bot".into(),
            phone_number_id: String::new(),
            access_token: String::new(),
            phone: String::new(),
            error_message: String::new(),
            session: c35_mod_channel::store::ChannelSession::default(),
        },
    );
    let long_msg = "Paragraph of text that repeats.\n\n".repeat(250);
    channel_reply(&client, &ctx, &long_msg, false).await.unwrap();

    let recorded = calls.lock().unwrap().clone();
    assert!(recorded.len() > 1, "Expected multiple chunked calls, got {}", recorded.len());
    for (path, body) in recorded {
        assert!(path.contains("/sendMessage"));
        let v: serde_json::Value = serde_json::from_str(&body).unwrap();
        assert_eq!(v["chat_id"], "881234567");
        let text = v["text"].as_str().unwrap();
        assert!(text.chars().count() <= c35_mod_channel::outbound::TG_TEXT_MAX);
    }
}

#[test]
fn telegram_parse_photo_and_document() {
    let payload = serde_json::json!({
        "update_id": 10,
        "message": {
            "message_id": 100,
            "from": { "id": 1234, "first_name": "Test" },
            "chat": { "id": 5678, "type": "private" },
            "caption": "Check this out",
            "photo": [
                { "file_id": "small_id", "file_size": 100, "width": 100, "height": 100 },
                { "file_id": "large_id", "file_size": 5000, "width": 800, "height": 800 }
            ]
        }
    })
    .to_string();
    let inbound = c35_mod_channel::telegram::parse_telegram_payload(payload.as_bytes()).unwrap();
    assert_eq!(inbound.text, "Check this out");
    assert_eq!(inbound.attachments.len(), 1);
    assert_eq!(inbound.attachments[0].media_id, "large_id");
    assert_eq!(inbound.attachments[0].mime, "image/jpeg");

    let doc_payload = serde_json::json!({
        "update_id": 11,
        "message": {
            "message_id": 101,
            "from": { "id": 1234, "first_name": "Test" },
            "chat": { "id": 5678, "type": "private" },
            "document": {
                "file_id": "doc_file_123",
                "file_name": "data.pdf",
                "mime_type": "application/pdf"
            }
        }
    })
    .to_string();
    let doc_inbound = c35_mod_channel::telegram::parse_telegram_payload(doc_payload.as_bytes()).unwrap();
    assert_eq!(doc_inbound.attachments.len(), 1);
    assert_eq!(doc_inbound.attachments[0].media_id, "doc_file_123");
    assert_eq!(doc_inbound.attachments[0].name, "data.pdf");
    assert_eq!(doc_inbound.attachments[0].mime, "application/pdf");
}

#[tokio::test]
async fn telegram_outbound_send_voice_reply() {
    let _lock = ENV_MUTEX.lock().unwrap();
    let captured = Arc::new(Mutex::new(None::<(String, String)>));
    let cap = captured.clone();
    let app = Router::new().fallback(any(move |uri: axum::http::Uri, _body: axum::body::Bytes| {
        let cap = cap.clone();
        async move {
            *cap.lock().unwrap() = Some((uri.to_string(), "voice_received".to_string()));
            Json(serde_json::json!({ "ok": true, "result": {} }))
        }
    }));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    tokio::time::sleep(Duration::from_millis(50)).await;

    let client = reqwest::Client::new();
    let api_base = format!("http://{addr}");
    let fake_audio = b"OggSfake_audio_bytes";
    let res = c35_mod_channel::telegram::tg_send_voice_reply(
        &client,
        &api_base,
        "token123",
        "881234567",
        fake_audio,
        "Hello voice",
    )
    .await;
    assert!(res.is_ok());
    let (path, _) = captured.lock().unwrap().clone().expect("voice received");
    assert!(path.contains("/sendVoice"));
}
