use anyhow::Result;
use c35_store::{migrate_apply, migrate_audit, migrate_boot, pool_connect};

#[tokio::main]
async fn main() -> Result<()> {
    let cmd = std::env::args().nth(1).unwrap_or_else(|| "audit".into());
    let pool = pool_connect().await?;
    match cmd.as_str() {
        "apply" => {
            migrate_apply(&pool).await?;
            migrate_boot(&pool).await?;
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
        "seed" => {
            let sql_path = std::path::Path::new("../_/schemas/object_normalizer_seeds.sql");
            if sql_path.exists() {
                let sql = std::fs::read_to_string(sql_path)?;
                println!("seeding object_normalizer from {}", sql_path.display());
                for stmt in c35_store::sql_stmts(&sql) {
                    if !stmt.trim().is_empty() {
                        sqlx::query(&stmt).execute(&pool).await?;
                    }
                }
                println!("seed: successfully applied object_normalizer_seeds.sql");
            } else {
                println!("seed file {} not found", sql_path.display());
            }
            let count_norm: (i64,) = sqlx::query_as("SELECT count(*) FROM ai.object_normalizer").fetch_one(&pool).await?;
            let count_alias: (i64,) = sqlx::query_as("SELECT count(*) FROM ai.object_alias").fetch_one(&pool).await?;
            let count_word: (i64,) = sqlx::query_as("SELECT count(*) FROM ai.word_normalizer").fetch_one(&pool).await?;
            println!("counts in DB: object_normalizer = {}, object_alias = {}, word_normalizer = {}", count_norm.0, count_alias.0, count_word.0);
        }
        other => anyhow::bail!("unknown command {other} (use: apply | audit | seed)"),
    }
    Ok(())
}
