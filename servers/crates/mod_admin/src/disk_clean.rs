use std::collections::HashSet;
use std::sync::LazyLock;

use c35_proto::{
    AdminDiskCleanKind, AdminDiskCleanStep, ReqAdminDiskClean, ResAdminDiskClean,
};
use k8s_openapi::api::apps::v1::Deployment;
use k8s_openapi::api::batch::v1::Job;
use k8s_openapi::api::core::v1::Pod;
use k8s_openapi::apimachinery::pkg::apis::meta::v1::ObjectMeta;
use kube::api::{Api, AttachParams, ListParams, Patch, PatchParams, PostParams};
use kube::Client;
use sqlx::PgPool;
use tokio::sync::Mutex;

use crate::{require_root, AdminError};

static DISK_CLEAN_LOCKS: LazyLock<Mutex<HashSet<String>>> =
    LazyLock::new(|| Mutex::new(HashSet::new()));

pub async fn admin_disk_clean(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqAdminDiskClean,
) -> Result<ResAdminDiskClean, AdminError> {
    require_root(pool, viewer_iid).await?;
    let node = req.node_name.trim();
    if node.is_empty() {
        return Err(AdminError::bad("node_name required"));
    }
    let lock_key = format!("{}:{}", node, req.kind);
    {
        let mut locks = DISK_CLEAN_LOCKS.lock().await;
        if !locks.insert(lock_key.clone()) {
            return Err(AdminError::bad("cleanup already running for this node and disk"));
        }
    }
    let kind = AdminDiskCleanKind::try_from(req.kind)
        .unwrap_or(AdminDiskCleanKind::AdminDiskCleanUnspecified);
    let result = match kind {
        AdminDiskCleanKind::AdminDiskCleanBoot => clean_boot(node).await,
        AdminDiskCleanKind::AdminDiskCleanYugabyte => clean_yugabyte(node, req.full).await,
        AdminDiskCleanKind::AdminDiskCleanBuildkit => clean_buildkit(req.full, req.force).await,
        AdminDiskCleanKind::AdminDiskCleanUnspecified => {
            Err(AdminError::bad("disk clean kind required"))
        }
    };
    DISK_CLEAN_LOCKS.lock().await.remove(&lock_key);
    match result {
        Ok(res) => Ok(res),
        Err(e) => {
            if e.status_code == 409 {
                return Err(e);
            }
            Ok(ResAdminDiskClean {
                ok: false,
                message: e.message,
                steps: vec![],
                used_bytes_after: None,
                total_bytes_after: None,
            })
        }
    }
}

async fn k8s_client() -> Result<Client, AdminError> {
    let cfg = kube::Config::infer()
        .await
        .map_err(|e| AdminError::bad(format!("kubernetes config: {e}")))?;
    Client::try_from(cfg).map_err(|e| AdminError::bad(format!("kubernetes client: {e}")))
}

fn step(name: &str, detail: impl Into<String>, ok: bool) -> AdminDiskCleanStep {
    AdminDiskCleanStep {
        name: name.to_string(),
        detail: detail.into(),
        ok,
    }
}

async fn clean_boot(node: &str) -> Result<ResAdminDiskClean, AdminError> {
    let client = k8s_client().await?;
    let ns = std::env::var("C35_DISK_CLEAN_NS").unwrap_or_else(|_| "c35".into());
    let jobs: Api<Job> = Api::namespaced(client.clone(), &ns);
    let script = include_str!("../scripts/node_boot_disk_clean.sh");
    let job_name = format!("c35-boot-clean-{}", chrono::Utc::now().timestamp());
    let job = boot_clean_job(&job_name, node, script);
    jobs.create(&PostParams::default(), &job)
        .await
        .map_err(|e| AdminError::bad(format!("create boot clean job: {e}")))?;

    let mut steps = vec![step("boot_job", format!("created job {job_name}"), true)];
    let (ok, log) = wait_job_log(&client, &ns, &job_name, 900).await?;
    steps.push(step("boot_job_run", log, ok));

    Ok(ResAdminDiskClean {
        ok,
        message: if ok {
            "boot disk cleanup finished".into()
        } else {
            "boot disk cleanup failed".into()
        },
        steps,
        used_bytes_after: None,
        total_bytes_after: None,
    })
}

fn boot_clean_job(name: &str, node: &str, script: &str) -> Job {
    let wrapped = format!(
        "set -euo pipefail; cat > /tmp/c35-boot-clean.sh <<'EOS'\n{script}\nEOS\nchmod +x /tmp/c35-boot-clean.sh; chroot /host bash /tmp/c35-boot-clean.sh"
    );
    let spec = serde_json::json!({
        "ttlSecondsAfterFinished": 600,
        "template": {
            "spec": {
                "nodeSelector": { "kubernetes.io/hostname": node },
                "restartPolicy": "Never",
                "containers": [{
                    "name": "janitor",
                    "image": "debian:bookworm-slim",
                    "securityContext": { "privileged": true },
                    "command": ["bash", "-c", wrapped],
                    "volumeMounts": [{ "name": "host", "mountPath": "/host" }]
                }],
                "volumes": [{
                    "name": "host",
                    "hostPath": { "path": "/", "type": "Directory" }
                }]
            }
        }
    });
    Job {
        metadata: ObjectMeta {
            name: Some(name.to_string()),
            labels: Some(
                [("app".to_string(), "c35-boot-clean".to_string())]
                    .into_iter()
                    .collect(),
            ),
            ..Default::default()
        },
        spec: serde_json::from_value(spec).ok(),
        ..Default::default()
    }
}

async fn wait_job_log(
    client: &Client,
    ns: &str,
    job_name: &str,
    timeout_secs: u64,
) -> Result<(bool, String), AdminError> {
    let pods: Api<Pod> = Api::namespaced(client.clone(), ns);
    let lp = ListParams::default().labels(&format!("job-name={job_name}"));
    let deadline =
        std::time::Instant::now() + std::time::Duration::from_secs(timeout_secs);
    let mut last_phase = String::new();
    while std::time::Instant::now() < deadline {
        let list = pods
            .list(&lp)
            .await
            .map_err(|e| AdminError::bad(format!("list job pods: {e}")))?;
        if let Some(pod) = list.items.first() {
            let phase = pod
                .status
                .as_ref()
                .and_then(|s| s.phase.clone())
                .unwrap_or_default();
            last_phase = phase.clone();
            if phase == "Succeeded" {
                let log = pod_logs(&pods, pod).await?;
                return Ok((true, log));
            }
            if phase == "Failed" {
                let log = pod_logs(&pods, pod).await?;
                return Ok((false, log));
            }
        }
        tokio::time::sleep(std::time::Duration::from_secs(3)).await;
    }
    Ok((false, format!("timeout waiting for job (last phase: {last_phase})")))
}

async fn pod_logs(pods: &Api<Pod>, pod: &Pod) -> Result<String, AdminError> {
    let name = pod.metadata.name.clone().unwrap_or_default();
    if name.is_empty() {
        return Ok(String::new());
    }
    let logs = pods
        .logs(&name, &Default::default())
        .await
        .map_err(|e| AdminError::bad(format!("pod logs: {e}")))?;
    Ok(truncate_detail(&logs, 4000))
}

async fn clean_yugabyte(node: &str, full: bool) -> Result<ResAdminDiskClean, AdminError> {
    let client = k8s_client().await?;
    let ns = "yugabyte";
    let pod = "yb-tserver-0";
    ensure_pod_on_node(&client, ns, pod, node).await?;

    let mut steps = Vec::new();
    let log_script = r"
set -e
if [ -x /mnt/disk0/yb-data/scripts/log_cleanup.sh ]; then
  /mnt/disk0/yb-data/scripts/log_cleanup.sh
elif [ -x /home/yugabyte/bin/log_cleanup.sh ]; then
  /home/yugabyte/bin/log_cleanup.sh
else
  echo log_cleanup.sh not found
  exit 1
fi
";
    let (ok, out) = exec_in_pod(&client, ns, pod, "yb-tserver", log_script).await?;
    steps.push(step("yb_log_cleanup", out, ok));
    if !ok {
        return Ok(ResAdminDiskClean {
            ok: false,
            message: "yugabyte log cleanup failed".into(),
            steps,
            used_bytes_after: None,
            total_bytes_after: None,
        });
    }

    if full {
        let compact = r#"
set -e
export LD_LIBRARY_PATH=/home/yugabyte/lib
MASTER=${YB_MASTER_ADDRESSES:-yb-master-0.yb-masters.yugabyte.svc.cluster.local:7100}
IDS=$(/home/yugabyte/bin/yb-admin --master_addresses "$MASTER" list_tables 2>/dev/null | sed -n 's/.*\[\(0000[^]]*\)\].*/\1/p' | sort -u)
n=0
for tid in $IDS; do
  n=$((n+1))
  /home/yugabyte/bin/yb-admin --master_addresses "$MASTER" compact_table_by_id "$tid" 120 || true
done
echo "compact pass done tables=$n"
"#;
        let (c_ok, c_out) = exec_in_pod(&client, ns, pod, "yb-tserver", compact).await?;
        steps.push(step("yb_compact", c_out, c_ok));
    }

    let ok = steps.iter().all(|s| s.ok);
    Ok(ResAdminDiskClean {
        ok,
        message: if ok {
            "yugabyte cleanup finished".into()
        } else {
            "yugabyte cleanup completed with errors".into()
        },
        steps,
        used_bytes_after: None,
        total_bytes_after: None,
    })
}

async fn clean_buildkit(full: bool, force: bool) -> Result<ResAdminDiskClean, AdminError> {
    let client = k8s_client().await?;
    let ns = "build";
    let deploy_name = "buildkit";
    let deployments: Api<Deployment> = Api::namespaced(client.clone(), ns);
    let dep = deployments
        .get(deploy_name)
        .await
        .map_err(|e| AdminError::bad(format!("get buildkit deployment: {e}")))?;
    let replicas = dep.spec.as_ref().and_then(|s| s.replicas).unwrap_or(0);
    let pods: Api<Pod> = Api::namespaced(client.clone(), ns);
    let lp = ListParams::default().labels("app=buildkit");
    let list = pods
        .list(&lp)
        .await
        .map_err(|e| AdminError::bad(format!("list buildkit pods: {e}")))?;
    let running = list.items.iter().any(|p| {
        p.status.as_ref().and_then(|s| s.phase.as_deref()) == Some("Running")
            && p.status
                .as_ref()
                .and_then(|s| s.container_statuses.as_ref())
                .and_then(|cs| cs.first())
                .map(|c| c.ready)
                .unwrap_or(false)
    });
    if running && replicas > 0 && !force {
        return Err(AdminError {
            status_code: 409,
            message: "buildkit_active".into(),
        });
    }

    let mut steps = Vec::new();
    scale_deployment(&deployments, deploy_name, 1).await?;
    steps.push(step("buildkit_scale_up", "replicas=1", true));

    let pod_name = wait_buildkit_pod(&pods, &lp, 180).await?;
    steps.push(step("buildkit_pod", pod_name.clone(), true));

    let keep = if full { "0s" } else { "168h" };
    let prune_cmd = format!("buildctl prune --all --keep-duration {keep}");
    let (ok, out) = exec_in_pod(&client, ns, &pod_name, "buildkitd", &prune_cmd).await?;
    steps.push(step("buildkit_prune", out, ok));

    scale_deployment(&deployments, deploy_name, 0).await?;
    steps.push(step("buildkit_scale_down", "replicas=0", true));

    Ok(ResAdminDiskClean {
        ok,
        message: if ok {
            "buildkit cache pruned".into()
        } else {
            "buildkit prune failed".into()
        },
        steps,
        used_bytes_after: None,
        total_bytes_after: None,
    })
}

async fn scale_deployment(
    api: &Api<Deployment>,
    name: &str,
    replicas: i32,
) -> Result<(), AdminError> {
    let patch = serde_json::json!({ "spec": { "replicas": replicas } });
    api.patch(name, &PatchParams::default(), &Patch::Merge(patch))
        .await
        .map_err(|e| AdminError::bad(format!("scale {name}: {e}")))?;
    Ok(())
}

async fn wait_buildkit_pod(
    pods: &Api<Pod>,
    lp: &ListParams,
    timeout_secs: u64,
) -> Result<String, AdminError> {
    let deadline =
        std::time::Instant::now() + std::time::Duration::from_secs(timeout_secs);
    while std::time::Instant::now() < deadline {
        let list = pods
            .list(lp)
            .await
            .map_err(|e| AdminError::bad(format!("list buildkit pods: {e}")))?;
        for pod in &list.items {
            let ready = pod
                .status
                .as_ref()
                .and_then(|s| s.container_statuses.as_ref())
                .and_then(|cs| cs.first())
                .map(|c| c.ready)
                .unwrap_or(false);
            if ready {
                if let Some(name) = pod.metadata.name.clone() {
                    return Ok(name);
                }
            }
        }
        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
    }
    Err(AdminError::bad("buildkit pod not ready"))
}

async fn ensure_pod_on_node(
    client: &Client,
    ns: &str,
    pod: &str,
    node: &str,
) -> Result<(), AdminError> {
    let pods: Api<Pod> = Api::namespaced(client.clone(), ns);
    let p = pods
        .get(pod)
        .await
        .map_err(|e| AdminError::bad(format!("get pod {ns}/{pod}: {e}")))?;
    let on_node = p
        .spec
        .as_ref()
        .and_then(|s| s.node_name.as_deref())
        .unwrap_or_default();
    if on_node != node {
        return Err(AdminError::bad(format!(
            "pod {pod} is on node {on_node}, not {node}"
        )));
    }
    Ok(())
}

async fn exec_in_pod(
    client: &Client,
    ns: &str,
    pod: &str,
    container: &str,
    script: &str,
) -> Result<(bool, String), AdminError> {
    let pods: Api<Pod> = Api::namespaced(client.clone(), ns);
    let cmd = vec!["bash", "-c", script];
    let mut attach = AttachParams::default();
    attach.container = Some(container.to_string());
    attach.stdout = true;
    attach.stderr = true;
    let mut exec = pods
        .exec(pod, cmd, &attach)
        .await
        .map_err(|e| AdminError::bad(format!("exec {ns}/{pod}: {e}")))?;
    let mut out = String::new();
    if let Some(mut reader) = exec.stdout() {
        use tokio::io::AsyncReadExt;
        let mut buf = vec![0u8; 4096];
        while let Ok(n) = reader.read(&mut buf).await {
            if n == 0 {
                break;
            }
            out.push_str(&String::from_utf8_lossy(&buf[..n]));
        }
    }
    if let Some(mut reader) = exec.stderr() {
        use tokio::io::AsyncReadExt;
        let mut buf = vec![0u8; 4096];
        while let Ok(n) = reader.read(&mut buf).await {
            if n == 0 {
                break;
            }
            out.push_str(&String::from_utf8_lossy(&buf[..n]));
        }
    }
    exec
        .join()
        .await
        .map_err(|e| AdminError::bad(format!("exec join: {e}")))?;
    let ok = true;
    Ok((ok, truncate_detail(&out, 4000)))
}

fn truncate_detail(s: &str, max: usize) -> String {
    if s.len() <= max {
        return s.to_string();
    }
    format!("{}...", &s[..max])
}
