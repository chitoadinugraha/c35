mod connect;
mod billing_kv;
mod bundle_kv;
mod hydrate;
mod stats_kv;
mod streams;
mod user_app;

pub use async_nats::Event;
pub use billing_kv::{
    billing_kv_delete, billing_kv_ensure, billing_kv_get, billing_kv_key_owner, billing_kv_put,
    BillingGateCached, BILLING_CACHE_TTL_SECS, BILLING_KV_BUCKET,
};
pub use bundle_kv::{
    device_presence_get, device_presence_kv_ensure, device_presence_put,
    hint_bundle_cache_delete, hint_bundle_cache_get, hint_bundle_cache_put, hint_bundle_kv_ensure,
    memory_bundle_delete, memory_bundle_get, memory_bundle_kv_ensure, memory_bundle_kv_key,
    memory_bundle_put, scope_inst_bundle_delete, scope_inst_bundle_get, scope_inst_kv_ensure,
    scope_inst_bundle_put, scope_inst_kv_key, BUNDLE_CACHE_TTL_SECS, DEVICE_PRESENCE_KV_BUCKET,
    HINT_BUNDLE_KV_BUCKET, MEMORY_BUNDLE_KV_BUCKET, PROMPT_BUNDLE_DISCONNECT_GRACE_SECS,
    PROMPT_BUNDLE_SESSION_KV_BUCKET, PromptBundleSession, SCOPE_INST_KV_BUCKET,
    prompt_bundle_disconnect_grace_secs, prompt_bundle_session_decode, prompt_bundle_session_encode,
    prompt_bundle_session_get, prompt_bundle_session_kv_ensure, prompt_bundle_session_kv_key,
    prompt_bundle_session_put,
};

pub use connect::{connect, connect_supervised, configured, Client};

pub use hydrate::{
    advisory_unlock, format_schedule_pattern, hydrate_task_schedules, task_schedule_arm, task_schedule_disarm,
    try_advisory_lock, HydrateAdvisoryLock, HydrateCounts, HYDRATE_LOCK_K1, HYDRATE_LOCK_K2,
};
pub use stats_kv::{
    stats_kv_ensure, stats_kv_get, stats_kv_get_bytes, stats_kv_key_node, stats_kv_key_pod,
    stats_kv_key_for_push, stats_kv_key_platform_user_count, stats_kv_key_volume,
    stats_kv_list_pushes, stats_kv_put,
    stats_kv_put_bytes, KV_BUCKET,
};
pub use streams::jetstream_streams_ensure;
pub use user_app::{
    user_app_fanout_decode, user_app_subject_balance, user_app_subject_chat, user_app_subject_commission,
    user_app_subject_inbox, user_app_subject_notify, user_app_subject_profile, user_app_subject_quota, user_app_subject_settings,
    user_app_subject_device_presence, user_app_subject_site_order, user_app_subject_task_run,
    user_app_subscribe_subject,
    user_app_tail, APP_SEGMENT,
};

