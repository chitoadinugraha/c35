use futures_util::StreamExt;
use prost::Message;
use sqlx::PgPool;
use tracing::{info, warn};

use c35_proto::FetchCaptchaRatesPush;

use crate::rates_cache::captcha_rates_reload_from_db;
use crate::rates_store::NATS_SUBJECT;

pub async fn captcha_rates_init(pool: &PgPool) -> Result<(), sqlx::Error> {
    captcha_rates_reload_from_db(pool).await
}

pub fn captcha_rates_nats_subscribe(pool: PgPool, nats: async_nats::Client) {
    tokio::spawn(async move {
        let mut sub = match nats.subscribe(NATS_SUBJECT).await {
            Ok(s) => s,
            Err(e) => {
                warn!(error = %e, "captcha_rates nats subscribe failed");
                return;
            }
        };
        while let Some(msg) = sub.next().await {
            if FetchCaptchaRatesPush::decode(msg.payload.as_ref()).is_ok() {
                if let Err(e) = captcha_rates_reload_from_db(&pool).await {
                    warn!(error = %e, "captcha_rates reload from nats failed");
                } else {
                    info!("captcha_rates reloaded from nats");
                }
            }
        }
    });
}
