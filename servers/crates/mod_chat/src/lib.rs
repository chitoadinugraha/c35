mod asset_tag;
mod bot_peer;
mod catalog;
mod chat_patch;
mod channel_prompt_turn;
mod inbox;
mod log_list;
pub mod compose;
mod inst;
mod inst_admin;
mod inst_cache;
mod site_resolve;
mod site_validate;
pub mod inst_macro;
mod mention;
mod mention_registry;
mod memory;
pub mod prompt;
mod prompt_turn;
mod topic;
pub mod tool_rag;
pub mod tools;
mod turn_tracer;

pub use catalog::{mention_list, topic_list, translation_get, translation_rev, CatalogMentionRow, CatalogTopicRow};
pub use mention::{mention_list_enabled, MentionRow};
pub use mention_registry::{
    mention_active_topic, mention_device_iids, mention_force_tools, mention_has_device,
    mention_list_rpc, mention_prompt_block, mention_ref_parse, mention_resolve_all,
    mention_search_rpc, MentionRef, MentionResolved,
};
pub use tools::ToolDef;

pub use asset_tag::asset_tag_list;
pub use bot_peer::{bot_peer_list, bot_peer_msg_list, chat_send, chat_stop};
pub use chat_patch::chat_patch;
pub use channel_prompt_turn::channel_prompt_turn;
pub use inbox::{chat_msg_list, inbox_list};
pub use log_list::log_list;
pub use inst_admin::{
    inst_delete, inst_get, inst_list, inst_publish_invalidation, inst_put, InstAdminError,
    NATS_SUBJECT_PREFIX,
};
pub use inst_cache::{
    inst_cache_init, inst_cache_nats_subscribe, inst_cache_reload_all, inst_cache_reload_one,
    inst_list_cached, NATS_SUBJECT_WILDCARD,
};
pub use inst_macro::{InstMatchCtx, InstRow};
pub use memory::{memory_prompt_merge, memory_put, memory_retrieve, MemoryRetrieveResult};
pub use prompt::audio;
pub use prompt::gemini::gemini_api_key;
pub use prompt_turn::{chat_ensure, chat_title_from_text, prompt_turn, PromptTurn};
pub use site_resolve::{site_at_tokens, site_context_block, site_context_resolve, SiteContext};
pub use site_validate::{
    block_props_allowed, validate_block, validate_object_keys, validate_sitedoc, BLOCK_TYPES, META_KEYS,
    THEME_KEYS,
};
