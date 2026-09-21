pub async fn task_report_progress(_task_run_id: i64, _progress: f32) -> anyhow::Result<()> {
    todo!("task_report_progress")
}

pub async fn task_report_done(_task_run_id: i64, _ok: bool, _detail: &str) -> anyhow::Result<()> {
    let _ = (_task_run_id, _ok, _detail);
    todo!("task_report_done")
}
