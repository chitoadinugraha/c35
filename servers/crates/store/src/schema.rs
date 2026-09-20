pub const IDENTITY_SQL: &str = include_str!("../../../../_/schemas/identity.sql");
pub const BILLING_SQL: &str = include_str!("../../../../_/schemas/billing.sql");
pub const CHAT_SQL: &str = include_str!("../../../../_/schemas/chat.sql");
pub const LOG_SQL: &str = include_str!("../../../../_/schemas/log.sql");
pub const EMBED_SQL: &str = include_str!("../../../../_/schemas/embed.sql");
pub const SKILL_SQL: &str = include_str!("../../../../_/schemas/skill.sql");
pub const CONSUMPTION_SQL: &str = include_str!("../../../../_/schemas/consumption.sql");
pub const SITE_SQL: &str = include_str!("../../../../_/schemas/site.sql");
pub const TX_SQL: &str = include_str!("../../../../_/schemas/tx.sql");

pub const SCHEMA_APPLY_ORDER: &[(&str, &str)] = &[
    ("identity", IDENTITY_SQL),
    ("billing", BILLING_SQL),
    ("chat", CHAT_SQL),
    ("log", LOG_SQL),
    ("embed", EMBED_SQL),
    ("skill", SKILL_SQL),
    ("consumption", CONSUMPTION_SQL),
    ("site", SITE_SQL),
    ("tx", TX_SQL),
];
