// HTTP helpers for skill RPCs — protobuf POST to /v1/skill/* and /v1/agent/task/*
// called from the agent's skill_dispatch / skill_explore / skill_heal / skill_submit modules.
// NOTE: Corresponding HTTP handlers are needed in wire_http on the server side.
use anyhow::{anyhow, Result};
use c35_proto::{
    pb_decode, pb_encode, EvDeviceTaskDone, EvDeviceTaskProgress, ReqSkillCatalogInstall,
    ReqSkillCatalogSearch, ReqSkillCatalogSubmit, ReqSkillPut, ReqSkillRunReport,
    ResSkillCatalogInstall, ResSkillCatalogSearch, ResSkillCatalogSubmit, ResSkillPut, Skill,
};

async fn agent_post(
    server_url: &str,
    session_key: &str,
    path: &str,
    payload: Vec<u8>,
) -> Result<bytes::Bytes> {
    let url = format!("{}{path}", server_url.trim_end_matches('/'));
    let bytes = reqwest::Client::new()
        .post(&url)
        .header("X-Device-Session", session_key)
        .header("Content-Type", "application/x-protobuf")
        .body(payload)
        .send()
        .await?
        .error_for_status()?
        .bytes()
        .await?;
    Ok(bytes)
}

pub async fn skill_put(server_url: &str, session_key: &str, skill: Skill) -> Result<Skill> {
    let payload = pb_encode(&ReqSkillPut { skill: Some(skill) });
    let bytes = agent_post(server_url, session_key, "/v1/skill/put", payload).await?;
    let res: ResSkillPut = pb_decode(&bytes)?;
    res.skill.ok_or_else(|| anyhow!("empty skill in response"))
}

pub async fn catalog_search(
    server_url: &str,
    session_key: &str,
    q: &str,
) -> Result<ResSkillCatalogSearch> {
    let payload = pb_encode(&ReqSkillCatalogSearch {
        q: q.to_string(),
        tags_json: String::new(),
        limit: 5,
        offset: 0,
    });
    let bytes = agent_post(server_url, session_key, "/v1/skill/catalog/search", payload).await?;
    pb_decode::<ResSkillCatalogSearch>(&bytes).map_err(|e| anyhow!("decode: {e}"))
}

pub async fn catalog_install(
    server_url: &str,
    session_key: &str,
    catalog_id: i64,
    device_iid: i64,
) -> Result<Skill> {
    let payload = pb_encode(&ReqSkillCatalogInstall {
        catalog_id,
        device_iid,
        scope: 2, // SKILL_SCOPE_DEVICE
        ..Default::default()
    });
    let bytes = agent_post(server_url, session_key, "/v1/skill/catalog/install", payload).await?;
    let res: ResSkillCatalogInstall = pb_decode(&bytes)?;
    res.skill.ok_or_else(|| anyhow!("empty skill in install response"))
}

pub async fn catalog_submit(
    server_url: &str,
    session_key: &str,
    req: ReqSkillCatalogSubmit,
) -> Result<ResSkillCatalogSubmit> {
    let payload = pb_encode(&req);
    let bytes = agent_post(server_url, session_key, "/v1/skill/catalog/submit", payload).await?;
    pb_decode::<ResSkillCatalogSubmit>(&bytes).map_err(|e| anyhow!("decode: {e}"))
}

pub async fn skill_run_report(
    server_url: &str,
    session_key: &str,
    skill_id: i64,
    success: bool,
    error: &str,
) -> Result<()> {
    let payload = pb_encode(&ReqSkillRunReport {
        skill_id,
        success,
        error: error.to_string(),
        ..Default::default()
    });
    // Fire and forget — failures are non-critical
    let _ = reqwest::Client::new()
        .post(&format!("{}/v1/skill/run_report", server_url.trim_end_matches('/')))
        .header("X-Device-Session", session_key)
        .header("Content-Type", "application/x-protobuf")
        .body(payload)
        .send()
        .await;
    Ok(())
}

pub async fn task_progress(
    server_url: &str,
    session_key: &str,
    run_id: i64,
    device_iid: i64,
    step_index: i32,
    topic: &str,
    text: &str,
    meta_json: &str,
) -> Result<()> {
    let payload = pb_encode(&EvDeviceTaskProgress {
        run_id,
        device_iid,
        step_index,
        topic: topic.to_string(),
        text: text.to_string(),
        meta_json: meta_json.to_string(),
    });
    let _ = reqwest::Client::new()
        .post(&format!("{}/v1/agent/task/progress", server_url.trim_end_matches('/')))
        .header("X-Device-Session", session_key)
        .header("Content-Type", "application/x-protobuf")
        .body(payload)
        .send()
        .await;
    Ok(())
}

pub async fn task_done(
    server_url: &str,
    session_key: &str,
    run_id: i64,
    device_iid: i64,
    ok: bool,
    detail: &str,
) -> Result<()> {
    let status = if ok { 4i32 } else { 5i32 }; // TASK_RUN_STATUS_DONE=4, FAILED=5
    let payload = pb_encode(&EvDeviceTaskDone {
        run_id,
        device_iid,
        status,
        summary: if ok { detail.to_string() } else { String::new() },
        error: if ok { String::new() } else { detail.to_string() },
        step_index: 0,
    });
    let _ = reqwest::Client::new()
        .post(&format!("{}/v1/agent/task/done", server_url.trim_end_matches('/')))
        .header("X-Device-Session", session_key)
        .header("Content-Type", "application/x-protobuf")
        .body(payload)
        .send()
        .await;
    Ok(())
}
