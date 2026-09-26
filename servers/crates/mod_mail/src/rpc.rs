use anyhow::Result;
use c35_ctx::AppState;
use c35_proto::{
    MailDirection, ReqMailDomainAdd, ReqMailDomainList, ReqMailGet, ReqMailList, ReqMailMailboxList, ReqMailSend,
    ResMailDomainAdd, ResMailDomainList, ResMailGet, ResMailList, ResMailMailboxList, ResMailSend,
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
    svc(state).list(caller, req.mailbox_id, direction, req.limit, req.before_message_id).await.map_err(err)
}

pub async fn mail_get_rpc(state: &AppState, caller: i64, req: ReqMailGet) -> Result<ResMailGet> {
    svc(state).get(caller, req.mailbox_id, req.message_id).await.map_err(err)
}

pub async fn mail_send_rpc(state: &AppState, caller: i64, req: ReqMailSend) -> Result<ResMailSend> {
    svc(state).send(caller, req.mailbox_id, &req.to_addr, &req.subject, &req.body_text, &req.body_html, &req.attachments).await.map_err(err)
}

pub async fn mail_mailbox_list_rpc(state: &AppState, caller: i64, _req: ReqMailMailboxList) -> Result<ResMailMailboxList> {
    mailbox::ensure_personal_on_first_access(&state.pool, caller).await.map_err(err)?;
    Ok(ResMailMailboxList { mailboxes: mailbox::list_for_user(&state.pool, caller).await.map_err(err)? })
}

pub async fn mail_domain_list_rpc(state: &AppState, caller: i64, _req: ReqMailDomainList) -> Result<ResMailDomainList> {
    Ok(ResMailDomainList { domains: domain::list_admin(&state.pool, caller).await.map_err(err)? })
}

pub async fn mail_domain_add_rpc(state: &AppState, caller: i64, req: ReqMailDomainAdd) -> Result<ResMailDomainAdd> {
    Ok(ResMailDomainAdd { domain: Some(domain::add_admin(&state.pool, caller, &req.hostname).await.map_err(err)?) })
}
