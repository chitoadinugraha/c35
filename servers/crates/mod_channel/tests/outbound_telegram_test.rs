use std::sync::{Arc, Mutex};
use std::time::Duration;

use axum::{routing::any, Json, Router};
use c35_mod_channel::outbound::{channel_reply, outbound_ctx_from_channel};
use c35_mod_channel::store::ChannelDoc;

#[tokio::test]
async fn telegram_outbound_send_message() {
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
    channel_reply(&client, &ctx, "hello telegram", false).await.unwrap();

    let (path, body) = captured.lock().unwrap().clone().expect("telegram sendMessage should be called");
    assert!(path.contains("/sendMessage"));
    let v: serde_json::Value = serde_json::from_str(&body).unwrap();
    assert_eq!(v["chat_id"], "881234567");
    assert_eq!(v["text"], "hello telegram");
}
