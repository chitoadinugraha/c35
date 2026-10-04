pub const IDENTITY_SQL: &str = include_str!("../../../../_/schemas/identity.sql");
pub const BILLING_SQL: &str = include_str!("../../../../_/schemas/billing.sql");
pub const CHAT_SQL: &str = include_str!("../../../../_/schemas/chat.sql");
pub const CHAT_FEEDBACK_SQL: &str = include_str!("../../../../_/schemas/chat_feedback.sql");
pub const BOT_INBOX_SQL: &str = include_str!("../../../../_/schemas/bot_inbox.sql");
pub const PROMPT_RUN_SQL: &str = include_str!("../../../../_/schemas/prompt_run.sql");
pub const PROMPT_FOLLOWUP_SQL: &str = include_str!("../../../../_/schemas/prompt_followup.sql");
pub const ASSET_TAG_SQL: &str = include_str!("../../../../_/schemas/asset_tag.sql");
pub const LOG_SQL: &str = include_str!("../../../../_/schemas/log.sql");
pub const EMBED_SQL: &str = include_str!("../../../../_/schemas/embed.sql");
pub const DATA_SOURCE_SQL: &str = include_str!("../../../../_/schemas/data_source.sql");
pub const YOUTUBE_TRANSCRIPT_SQL: &str = include_str!("../../../../_/schemas/youtube_transcript.sql");
pub const SKILL_SQL: &str = include_str!("../../../../_/schemas/skill.sql");
pub const TASK_SQL: &str = include_str!("../../../../_/schemas/task.sql");
pub const CONSUMPTION_SQL: &str = include_str!("../../../../_/schemas/consumption.sql");
pub const SITE_SQL: &str = include_str!("../../../../_/schemas/site.sql");
pub const MAIL_SQL: &str = include_str!("../../../../_/schemas/mail.sql");
pub const TX_SQL: &str = include_str!("../../../../_/schemas/tx.sql");
pub const FILE_SQL: &str = include_str!("../../../../_/schemas/file.sql");
pub const DRIVE_SQL: &str = include_str!("../../../../_/schemas/drive.sql");
pub const TOOL_ARTIFACT_SQL: &str = include_str!("../../../../_/schemas/tool_artifact.sql");
pub const INST_SQL: &str = include_str!("../../../../_/schemas/inst.sql");
pub const TOPIC_SQL: &str = include_str!("../../../../_/schemas/topic.sql");
pub const MENTION_SQL: &str = include_str!("../../../../_/schemas/mention.sql");
pub const TRANSLATION_SQL: &str = include_str!("../../../../_/schemas/translation.sql");
pub const PRESENTATION_THEME_SQL: &str = include_str!("../../../../_/schemas/presentation_theme.sql");
pub const HINT_SQL: &str = include_str!("../../../../_/schemas/hint.sql");
pub const MEMORY_SQL: &str = include_str!("../../../../_/schemas/memory.sql");
pub const OBJECT_NORMALIZER_SQL: &str = include_str!("../../../../_/schemas/object_normalizer.sql");
pub const CHANNEL_SQL: &str = include_str!("../../../../_/schemas/channel.sql");
pub const CONFIG_SQL: &str = include_str!("../../../../_/schemas/config.sql");
pub const OPS_SQL: &str = include_str!("../../../../_/schemas/ops.sql");

pub const SCHEMA_APPLY_ORDER: &[(&str, &str)] = &[
    ("identity", IDENTITY_SQL),
    ("mail", MAIL_SQL),
    ("billing", BILLING_SQL),
    ("chat", CHAT_SQL),
    ("chat_feedback", CHAT_FEEDBACK_SQL),
    ("bot_inbox", BOT_INBOX_SQL),
    ("prompt_run", PROMPT_RUN_SQL),
    ("prompt_followup", PROMPT_FOLLOWUP_SQL),
    ("asset_tag", ASSET_TAG_SQL),
    ("log", LOG_SQL),
    ("embed", EMBED_SQL),
    ("data_source", DATA_SOURCE_SQL),
    ("youtube_transcript", YOUTUBE_TRANSCRIPT_SQL),
    ("inst", INST_SQL),
    ("topic", TOPIC_SQL),
    ("mention", MENTION_SQL),
    ("translation", TRANSLATION_SQL),
    ("presentation_theme", PRESENTATION_THEME_SQL),
    ("hint", HINT_SQL),
    ("memory", MEMORY_SQL),
    ("skill", SKILL_SQL),
    ("task", TASK_SQL),
    ("consumption", CONSUMPTION_SQL),
    ("object_normalizer", OBJECT_NORMALIZER_SQL),
    ("site", SITE_SQL),
    ("tx", TX_SQL),
    ("file", FILE_SQL),
    ("drive", DRIVE_SQL),
    ("tool_artifact", TOOL_ARTIFACT_SQL),
    ("channel", CHANNEL_SQL),
    ("config", CONFIG_SQL),
    ("ops", OPS_SQL),
];
