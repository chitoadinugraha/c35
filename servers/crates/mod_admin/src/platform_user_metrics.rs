use crate::{require_root, AdminError};
use c35_mod_platform::platform_user_metrics_query;
use c35_proto::{ReqAdminPlatformUserMetrics, ResAdminPlatformUserMetrics};
use sqlx::PgPool;

pub async fn admin_platform_user_metrics(
    pool: &PgPool,
    viewer_iid: i64,
    _req: ReqAdminPlatformUserMetrics,
) -> Result<ResAdminPlatformUserMetrics, AdminError> {
    require_root(pool, viewer_iid).await?;
    let m = platform_user_metrics_query(pool)
        .await
        .map_err(|e| AdminError::bad(e.to_string()))?;
    Ok(ResAdminPlatformUserMetrics {
        users: Some(m.users),
        active_users: Some(m.active_users),
        paid_users: Some(m.paid_users),
        total_users: m.total_users,
    })
}
