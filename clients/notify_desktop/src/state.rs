use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, RwLock};

use tokio::sync::{broadcast, watch};

pub struct AppState {
    pub resumed: AtomicBool,
    pub focused: AtomicBool,
    jwt: RwLock<Option<String>>,
    jwt_watch: watch::Sender<Option<String>>,
    pub push_tx: broadcast::Sender<String>,
}

impl AppState {
    pub fn new() -> Arc<Self> {
        let initial_jwt = crate::config::jwt_from_env_or_file();
        let (jwt_watch, _) = watch::channel(initial_jwt.clone());
        let (push_tx, _) = broadcast::channel(64);
        Arc::new(Self {
            resumed: AtomicBool::new(false),
            focused: AtomicBool::new(false),
            jwt: RwLock::new(initial_jwt),
            jwt_watch,
            push_tx,
        })
    }

    pub fn jwt_snapshot(&self) -> Option<String> {
        self.jwt.read().ok().and_then(|g| g.clone())
    }

    pub fn set_jwt(&self, token: String) {
        let t = token.trim();
        if t.is_empty() {
            return;
        }
        if let Ok(mut g) = self.jwt.write() {
            *g = Some(t.to_string());
        }
        let _ = self.jwt_watch.send(Some(t.to_string()));
    }

    pub fn jwt_watch(&self) -> watch::Receiver<Option<String>> {
        self.jwt_watch.subscribe()
    }

    pub fn resumed(&self) -> bool {
        self.resumed.load(Ordering::Relaxed)
    }

    pub fn set_resumed(&self, v: bool) {
        self.resumed.store(v, Ordering::Relaxed);
    }

    pub fn set_focused(&self, v: bool) {
        self.focused.store(v, Ordering::Relaxed);
    }

    pub fn broadcast_ipc(&self, line: String) {
        let _ = self.push_tx.send(line);
    }
}
