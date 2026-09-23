pub const IDENTITY_SQL: &str = include_str!("../../../../_/schemas/identity.sql");
pub const BILLING_SQL: &str = include_str!("../../../../_/schemas/billing.sql");
pub const CHAT_SQL: &str = include_str!("../../../../_/schemas/chat.sql");
pub const PROMPT_RUN_SQL: &str = include_str!("../../../../_/schemas/prompt_run.sql");
pub const ASSET_TAG_SQL: &str = include_str!("../../../../_/schemas/asset_tag.sql");
pub const LOG_SQL: &str = include_str!("../../../../_/schemas/log.sql");
pub const EMBED_SQL: &str = include_str!("../../../../_/schemas/embed.sql");
pub const SKILL_SQL: &str = include_str!("../../../../_/schemas/skill.sql");
pub const TASK_SQL: &str = include_str!("../../../../_/schemas/task.sql");
pub const CONSUMPTION_SQL: &str = include_str!("../../../../_/schemas/consumption.sql");
pub const SITE_SQL: &str = include_str!("../../../../_/schemas/site.sql");
pub const TX_SQL: &str = include_str!("../../../../_/schemas/tx.sql");
pub const FILE_SQL: &str = include_str!("../../../../_/schemas/file.sql");
pub const INST_SQL: &str = include_str!("../../../../_/schemas/inst.sql");
pub const TOPIC_SQL: &str = include_str!("../../../../_/schemas/topic.sql");
pub const MENTION_SQL: &str = include_str!("../../../../_/schemas/mention.sql");
pub const TRANSLATION_SQL: &str = include_str!("../../../../_/schemas/translation.sql");
pub const HINT_SQL: &str = include_str!("../../../../_/schemas/hint.sql");
pub const MEMORY_SQL: &str = include_str!("../../../../_/schemas/memory.sql");
pub const OBJECT_NORMALIZER_SQL: &str = include_str!("../../../../_/schemas/object_normalizer.sql");
pub const CHANNEL_SQL: &str = include_str!("../../../../_/schemas/channel.sql");
pub const CONFIG_SQL: &str = include_str!("../../../../_/schemas/config.sql");

pub const SCHEMA_APPLY_ORDER: &[(&str, &str)] = &[
    ("identity", IDENTITY_SQL),
    ("billing", BILLING_SQL),
    ("chat", CHAT_SQL),
    ("prompt_run", PROMPT_RUN_SQL),
    ("asset_tag", ASSET_TAG_SQL),
    ("log", LOG_SQL),
    ("embed", EMBED_SQL),
    ("inst", INST_SQL),
    ("topic", TOPIC_SQL),
    ("mention", MENTION_SQL),
    ("translation", TRANSLATION_SQL),
    ("hint", HINT_SQL),
    ("memory", MEMORY_SQL),
    ("skill", SKILL_SQL),
    ("task", TASK_SQL),
    ("consumption", CONSUMPTION_SQL),
    ("object_normalizer", OBJECT_NORMALIZER_SQL),
    ("site", SITE_SQL),
    ("tx", TX_SQL),
    ("file", FILE_SQL),
    ("channel", CHANNEL_SQL),
    ("config", CONFIG_SQL),
];
