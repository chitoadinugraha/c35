mod access;
mod attachments;
mod client;
mod cloudflare;
mod domain;
mod events;
mod http;
mod inbound;
mod mailbox;
mod outbound;
mod rpc;
mod service;

pub use client::{mail_push_offline, mail_push_offline_fn_set, mail_user_notify_fn_set, mail_user_notify_json};
pub use http::mail_router;
pub use inbound::{inbound_webhook, verify_inbound_signature, MailInboundPayload};
pub use outbound::SmtpConfig;
pub use mailbox::{inbox_unread_total, nav_mail_snapshot};
pub use rpc::{
    mail_account_get_rpc, mail_archive_rpc, mail_broadcast_rpc, mail_domain_add_rpc, mail_domain_fix_rpc,
    mail_domain_list_rpc, mail_get_rpc, mail_group_delete_rpc, mail_group_list_rpc, mail_group_upsert_rpc,
    mail_list_rpc, mail_mailbox_admin_list_rpc, mail_mailbox_create_rpc, mail_mailbox_delete_rpc,
    mail_mailbox_list_rpc, mail_mailbox_update_rpc, mail_mark_read_rpc, mail_send_rpc,
};

pub fn init() {
    tracing::debug!("mod_mail: init");
}
