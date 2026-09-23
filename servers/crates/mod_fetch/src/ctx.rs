use async_nats::Client;
use reqwest::Client as HttpClient;
use sqlx::PgPool;

pub struct FetchCtx {
    pub pool: PgPool,
    pub nats: Client,
    pub http: HttpClient,
}
