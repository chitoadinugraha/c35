use std::collections::HashMap;
use std::sync::{Arc, OnceLock};
pub type MailUserNotifyFn = Arc<dyn Fn(i64, serde_json::Value) + Send + Sync>;
pub type MailPushOfflineFn = Arc<dyn Fn(i64, String, String, HashMap<String, String>) + Send + Sync>;
static A: OnceLock<MailUserNotifyFn> = OnceLock::new();
static B: OnceLock<MailPushOfflineFn> = OnceLock::new();
pub fn mail_user_notify_fn_set(f: MailUserNotifyFn) { let _ = A.set(f); }
pub fn mail_user_notify_json(uid: i64, p: serde_json::Value) { if uid != 0 { A.get().map(|f| f(uid, p)); } }
pub fn mail_push_offline_fn_set(f: MailPushOfflineFn) { let _ = B.set(f); }
pub fn mail_push_offline(uid: i64, t: impl Into<String>, b: impl Into<String>, d: HashMap<String, String>) { if uid != 0 { B.get().map(|f| f(uid, t.into(), b.into(), d)); } }
