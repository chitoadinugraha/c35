use serde_json::Value;

#[derive(Debug, Clone)]
pub struct AgentProfile {
    pub owner_alien_id: String,
    pub owner_name: String,
    pub device_name: String,
    pub device_iid: i64,
    pub personal_package_name: String,
    pub device_package_name: String,
    pub storage_used_bytes: Option<i64>,
    pub storage_limit_bytes: Option<i64>,
}

pub fn owner_display(profile: &AgentProfile) -> String {
    let name = profile.owner_name.trim();
    let id = profile.owner_alien_id.trim();
    if name.is_empty() {
        id.to_string()
    } else if id.is_empty() || name.eq_ignore_ascii_case(id) {
        name.to_string()
    } else {
        format!("{name} (@{id})")
    }
}

fn pick_str(v: &Value, keys: &[&str]) -> Option<String> {
    for k in keys {
        if let Some(s) = v.get(k).and_then(|x| x.as_str()) {
            let t = s.trim();
            if !t.is_empty() {
                return Some(t.to_string());
            }
        }
    }
    None
}

fn pick_i64_nonneg(v: &Value, keys: &[&str]) -> Option<i64> {
    for k in keys {
        if let Some(n) = v.get(k).and_then(|x| x.as_i64()) {
            if n >= 0 {
                return Some(n);
            }
        }
        if let Some(s) = v.get(k).and_then(|x| x.as_str()) {
            if let Ok(n) = s.trim().parse::<i64>() {
                if n >= 0 {
                    return Some(n);
                }
            }
        }
    }
    None
}

fn pick_i64(v: &Value, keys: &[&str]) -> Option<i64> {
    for k in keys {
        if let Some(n) = v.get(k).and_then(|x| x.as_i64()) {
            if n > 0 {
                return Some(n);
            }
        }
        if let Some(s) = v.get(k).and_then(|x| x.as_str()) {
            if let Ok(n) = s.trim().parse::<i64>() {
                if n > 0 {
                    return Some(n);
                }
            }
        }
    }
    None
}

fn profile_from_json(v: &Value) -> Option<AgentProfile> {
    let root = v
        .get("profile")
        .or_else(|| v.get("data"))
        .unwrap_or(v);

    let owner_alien_id = pick_str(
        root,
        &[
            "owner_alien_id",
            "ownerAlienId",
            "owner_id",
            "ownerAlienID",
        ],
    )?;
    let owner_name = pick_str(
        root,
        &["owner_name", "ownerName", "owner_display_name", "ownerDisplayName"],
    )
        .unwrap_or_else(|| owner_alien_id.clone());
    let device_name = pick_str(root, &["device_name", "deviceName", "name", "label"])
        .unwrap_or_default();
    let device_iid = pick_i64(root, &["device_iid", "deviceIid", "iid"]).unwrap_or(0);
    let personal_package_name = pick_str(
        root,
        &[
            "personal_package_name",
            "personalPackageName",
            "package_personal_name",
        ],
    )
        .unwrap_or_else(|| "—".to_string());
    let device_package_name = pick_str(
        root,
        &[
            "device_package_name",
            "devicePackageName",
            "package_device_name",
        ],
    )
        .unwrap_or_else(|| "—".to_string());
    let storage_used_bytes = pick_i64_nonneg(
        root,
        &["storage_used_bytes", "storageUsedBytes"],
    );
    let storage_limit_bytes = pick_i64_nonneg(
        root,
        &["storage_limit_bytes", "storageLimitBytes"],
    );

    Some(AgentProfile {
        owner_alien_id,
        owner_name,
        device_name,
        device_iid,
        personal_package_name,
        device_package_name,
        storage_used_bytes,
        storage_limit_bytes,
    })
}

pub async fn agent_profile_fetch(base_url: &str, session_key: &str) -> Option<AgentProfile> {
    let key = session_key.trim();
    if key.is_empty() {
        return None;
    }
    let url = format!("{}/v1/agent/profile", base_url.trim_end_matches('/'));
    let res = reqwest::Client::new()
        .get(&url)
        .header("X-Device-Session", key)
        .send()
        .await;
    match res {
        Ok(r) if r.status().is_success() => {
            let body = r.json::<Value>().await.ok()?;
            profile_from_json(&body)
        }
        Ok(r) => {
            tracing::debug!(status = r.status().as_u16(), "agent profile fetch failed");
            None
        }
        Err(e) => {
            tracing::debug!(error = %e, "agent profile request error");
            None
        }
    }
}