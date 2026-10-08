use std::collections::HashMap;

use crate::async_trait;
use crate::FcmSend;

/// Wraps `c35_fcm::Fcm` so delivery can take `&dyn FcmSend`.
/// `c35_fcm` does not depend on this crate.
pub struct NotifyFcm {
    inner: c35_fcm::Fcm,
}

impl NotifyFcm {
    pub fn from_env() -> Self {
        Self {
            inner: c35_fcm::Fcm::from_env(),
        }
    }
}

#[async_trait]
impl FcmSend for NotifyFcm {
    async fn send_data(&self, tokens: &[String], data: HashMap<String, String>) {
        if let Err(err) = self.inner.send_data(tokens, data).await {
            tracing::warn!(error = %err, "[c35:notify] fcm send failed");
        }
    }
}
