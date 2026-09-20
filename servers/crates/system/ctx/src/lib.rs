use sqlx::PgPool;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub jwt_secret: String,
}

#[derive(Clone)]
pub struct Ctx {
    pub pool: PgPool,
    pub caller_iid: i64,
}

impl Ctx {
    pub fn from_state(state: &AppState, caller_iid: i64) -> Self {
        Self {
            pool: state.pool.clone(),
            caller_iid,
        }
    }
}
