use anyhow::Result;
use c35_ctx::AppState;
use c35_proto::{
    MailDirection, MailMailboxKind, ReqMailAccountGet, ReqMailArchive, ReqMailBroadcast, ReqMailDomainAdd,
    ReqMailDomainFix, ReqMailDomainList, ReqMailGet, ReqMailGroupDelete, ReqMailGroupList, ReqMailGroupUpsert,
    ReqMailList, ReqMailMailboxAdminList, ReqMailMailboxCreate, ReqMailMailboxDelete, ReqMailMailboxList,
    ReqMailMailboxUpdate, ReqMailMarkRead, ReqMailSend, ResMailAccountGet, ResMailArchive, ResMailBroadcast,
    MailBroadcastFailure, ResMailDomainAdd, ResMailDomainFix, ResMailDomainList, ResMailGet, ResMailGroupDelete,
    ResMailGroupList, ResMailGroupUpsert, ResMailList, ResMailMailboxAdminList, ResMailMailboxCreate,
    ResMailMailboxDelete, ResMailMailboxList, ResMailMailboxUpdate, ResMailMarkRead, ResMailSend,
};
use crate::attachments::MailCas;
use crate::domain;
use crate::mailbox;
use crate::service::MailService;

fn cas(state: &AppState) -> MailCas {
    MailCas { pool: state.pool.clone(), cas_dir: state.cas_dir.clone(), cas_secret: state.cas_secret.clone() }
}

fn svc(state: &AppState) -> MailService {
    MailService::new(state.pool.clone(), Some(cas(state)))
}

fn err(e: String) -> anyhow::Error { anyhow::anyhow!(e) }

pub async fn mail_list_rpc(state: &AppState, caller: i64, req: ReqMailList) -> Result<ResMailList> {
    let direction = MailDirection::try_from(req.direction).unwrap_or(MailDirection::Unspecified);
    svc(state)
        .list(caller, req.mailbox_id, direction, req.limit, req.before_message_id, req.is_archived)
        .await
        .map_err(err)
}

pub async fn mail_get_rpc(state: &AppState, caller: i64, req: ReqMailGet) -> Result<ResMailGet> {
    svc(state).get(caller, req.mailbox_id, req.message_id).await.map_err(err)
}

pub async fn mail_send_rpc(state: &AppState, caller: i64, req: ReqMailSend) -> Result<ResMailSend> {
    svc(state)
        .send(caller, req.mailbox_id, &req.to_addr, &req.subject, &req.body_text, &req.body_html, &req.attachments)
        .await
        .map_err(err)
}

pub async fn mail_account_get_rpc(state: &AppState, caller: i64, _req: ReqMailAccountGet) -> Result<ResMailAccountGet> {
    svc(state).account_get(caller).await.map_err(err)
}

pub async fn mail_archive_rpc(state: &AppState, caller: i64, req: ReqMailArchive) -> Result<ResMailArchive> {
    let count = svc(state)
        .archive_messages(caller, req.mailbox_id, &req.message_ids, req.archive)
        .await
        .map_err(err)?;
    Ok(ResMailArchive { count })
}

pub async fn mail_mark_read_rpc(state: &AppState, caller: i64, req: ReqMailMarkRead) -> Result<ResMailMarkRead> {
    let (count, inbox_unread_count) = svc(state)
        .mark_read(caller, req.mailbox_id, &req.message_ids, req.read)
        .await
        .map_err(err)?;
    Ok(ResMailMarkRead { count, inbox_unread_count })
}

pub async fn mail_group_list_rpc(state: &AppState, caller: i64, req: ReqMailGroupList) -> Result<ResMailGroupList> {
    let groups = svc(state).group_list(caller, req.mailbox_id).await.map_err(err)?;
    Ok(ResMailGroupList { groups })
}

pub async fn mail_group_upsert_rpc(state: &AppState, caller: i64, req: ReqMailGroupUpsert) -> Result<ResMailGroupUpsert> {
    let group_in = req.group.ok_or_else(|| err("missing group".to_string()))?;
    let group = svc(state).group_upsert(caller, req.mailbox_id, group_in).await.map_err(err)?;
    Ok(ResMailGroupUpsert { group: Some(group) })
}

pub async fn mail_group_delete_rpc(state: &AppState, caller: i64, req: ReqMailGroupDelete) -> Result<ResMailGroupDelete> {
    let success = svc(state).group_delete(caller, req.mailbox_id, &req.group_id).await.map_err(err)?;
    Ok(ResMailGroupDelete { success })
}

pub async fn mail_broadcast_rpc(state: &AppState, caller: i64, req: ReqMailBroadcast) -> Result<ResMailBroadcast> {
    let result = svc(state)
        .broadcast_detailed(
            caller,
            req.mailbox_id,
            &req.group_id,
            &req.custom_emails,
            &req.subject,
            &req.body_text,
            &req.body_html,
            &req.attachments,
        )
        .await
        .map_err(err)?;
    Ok(ResMailBroadcast {
        queued_count: result.sent_count,
        failures: result
            .failures
            .into_iter()
            .map(|(to_addr, error)| MailBroadcastFailure { to_addr, error })
            .collect(),
    })
}

pub async fn mail_mailbox_list_rpc(state: &AppState, caller: i64, _req: ReqMailMailboxList) -> Result<ResMailMailboxList> {
    mailbox::ensure_personal_on_first_access(&state.pool, caller).await.map_err(err)?;
    Ok(ResMailMailboxList { mailboxes: mailbox::list_for_user(&state.pool, caller).await.map_err(err)? })
}

pub async fn mail_mailbox_admin_list_rpc(
    state: &AppState,
    caller: i64,
    _req: ReqMailMailboxAdminList,
) -> Result<ResMailMailboxAdminList> {
    Ok(ResMailMailboxAdminList { mailboxes: mailbox::admin_list(&state.pool, caller).await.map_err(err)? })
}

pub async fn mail_mailbox_create_rpc(state: &AppState, caller: i64, req: ReqMailMailboxCreate) -> Result<ResMailMailboxCreate> {
    let kind = MailMailboxKind::try_from(req.kind).unwrap_or(MailMailboxKind::Unspecified);
    let mailbox = mailbox::admin_create(
        &state.pool,
        caller,
        kind,
        req.site_iid,
        &req.address,
        &req.label,
        req.subscriber_limit,
        req.members,
    )
    .await
    .map_err(err)?;
    Ok(ResMailMailboxCreate { mailbox: Some(mailbox) })
}

pub async fn mail_mailbox_update_rpc(state: &AppState, caller: i64, req: ReqMailMailboxUpdate) -> Result<ResMailMailboxUpdate> {
    let mailbox = mailbox::admin_update(
        &state.pool,
        caller,
        req.mailbox_id,
        &req.label,
        req.subscriber_limit,
        req.members,
    )
    .await
    .map_err(err)?;
    Ok(ResMailMailboxUpdate { mailbox: Some(mailbox) })
}

pub async fn mail_mailbox_delete_rpc(state: &AppState, caller: i64, req: ReqMailMailboxDelete) -> Result<ResMailMailboxDelete> {
    let success = mailbox::admin_delete(&state.pool, caller, req.mailbox_id).await.map_err(err)?;
    Ok(ResMailMailboxDelete { success })
}

pub async fn mail_domain_list_rpc(state: &AppState, caller: i64, _req: ReqMailDomainList) -> Result<ResMailDomainList> {
    Ok(ResMailDomainList { domains: domain::list_admin(&state.pool, caller).await.map_err(err)? })
}

pub async fn mail_domain_add_rpc(state: &AppState, caller: i64, req: ReqMailDomainAdd) -> Result<ResMailDomainAdd> {
    Ok(ResMailDomainAdd { domain: Some(domain::add_admin(&state.pool, caller, &req.hostname).await.map_err(err)?) })
}

pub async fn mail_domain_fix_rpc(state: &AppState, caller: i64, req: ReqMailDomainFix) -> Result<ResMailDomainFix> {
    Ok(ResMailDomainFix { domain: Some(domain::fix_admin(&state.pool, caller, &req.hostname).await.map_err(err)?) })
}
