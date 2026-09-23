use anyhow::Result;
use c35_store::{migrate_apply, migrate_audit, migrate_boot, pool_connect};

#[tokio::main]
async fn main() -> Result<()> {
    let cmd = std::env::args().nth(1).unwrap_or_else(|| "audit".into());
    let pool = pool_connect().await?;
    match cmd.as_str() {
        "apply" => {
            migrate_boot(&pool).await?;
            migrate_apply(&pool).await?;
            println!("migrate: applied all schemas");
            let report = migrate_audit(&pool).await?;
            report.print();
            if !report.missing.is_empty() {
                anyhow::bail!("{} table(s) still missing after apply", report.missing.len());
            }
        }
        "audit" => {
            let report = migrate_audit(&pool).await?;
            report.print();
            if !report.missing.is_empty() {
                std::process::exit(1);
            }
        }
        other => anyhow::bail!("unknown command {other} (use: apply | audit)"),
    }
    Ok(())
}
