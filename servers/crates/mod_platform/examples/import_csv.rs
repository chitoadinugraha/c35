use anyhow::{bail, Context, Result};
use chrono::NaiveDate;
use c35_mod_platform::{
    parse_vendor_csv, vendor_cost_finalize_period, vendor_cost_upsert_batch,
};
use c35_store::pool_connect;
use std::env;

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();
    let cfg = parse_args()?;
    let bytes = std::fs::read(&cfg.path).with_context(|| format!("read {}", cfg.path))?;
    let lines = parse_vendor_csv(
        &cfg.vendor,
        &bytes,
        cfg.period_start,
        cfg.period_end,
        &cfg.category,
        cfg.finalize,
    )?;
    eprintln!(
        "parsed {} line(s) for vendor={} period={}..{}",
        lines.len(),
        cfg.vendor,
        cfg.period_start,
        cfg.period_end
    );
    if cfg.dry_run {
        for line in &lines {
            eprintln!(
                "  {} {} {} {:.4} {} [{}]",
                line.sku,
                line.category,
                line.description,
                line.amount_native,
                line.currency,
                line.status
            );
        }
        return Ok(());
    }
    let pool = pool_connect().await.context("pool_connect (set DATABASE_URL or YB_*)")?;
    let n = vendor_cost_upsert_batch(&pool, &lines).await?;
    eprintln!("upserted {} row(s)", n);
    if cfg.finalize {
        let finalized = vendor_cost_finalize_period(
            &pool,
            &cfg.vendor,
            cfg.period_start,
            cfg.period_end,
        )
        .await?;
        eprintln!("finalized {} row(s) for period", finalized);
    }
    Ok(())
}

struct ImportCfg {
    vendor: String,
    path: String,
    period_start: NaiveDate,
    period_end: NaiveDate,
    category: String,
    finalize: bool,
    dry_run: bool,
}

fn parse_args() -> Result<ImportCfg> {
    let mut vendor = None;
    let mut path = None;
    let mut period_start = None;
    let mut period_end = None;
    let mut category = "other".to_string();
    let mut finalize = false;
    let mut dry_run = false;
    let args: Vec<String> = env::args().skip(1).collect();
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--vendor" | "-Vendor" => {
                i += 1;
                vendor = Some(next_arg(&args, i, "vendor")?);
            }
            "--path" | "-Path" => {
                i += 1;
                path = Some(next_arg(&args, i, "path")?);
            }
            "--period-start" | "-PeriodStart" => {
                i += 1;
                period_start = Some(parse_date(&next_arg(&args, i, "period-start")?)?);
            }
            "--period-end" | "-PeriodEnd" => {
                i += 1;
                period_end = Some(parse_date(&next_arg(&args, i, "period-end")?)?);
            }
            "--category" | "-Category" => {
                i += 1;
                category = next_arg(&args, i, "category")?;
            }
            "--finalize" | "-Finalize" => finalize = true,
            "--dry-run" | "-DryRun" => dry_run = true,
            "-h" | "--help" => {
                print_help();
                std::process::exit(0);
            }
            other => bail!("unknown arg: {}", other),
        }
        i += 1;
    }
    let vendor = vendor.context("--vendor required")?;
    validate_vendor(&vendor)?;
    let path = path.context("--path required")?;
    let period_start = period_start.context("--period-start required (YYYY-MM-DD)")?;
    let period_end = period_end.context("--period-end required (YYYY-MM-DD)")?;
    if period_end < period_start {
        bail!("period-end must be >= period-start");
    }
    Ok(ImportCfg {
        vendor,
        path,
        period_start,
        period_end,
        category,
        finalize,
        dry_run,
    })
}

fn next_arg(args: &[String], i: usize, name: &str) -> Result<String> {
    args.get(i)
        .map(|s| s.to_string())
        .with_context(|| format!("missing value for {}", name))
}

fn parse_date(raw: &str) -> Result<NaiveDate> {
    NaiveDate::parse_from_str(raw, "%Y-%m-%d")
        .with_context(|| format!("invalid date {} (expected YYYY-MM-DD)", raw))
}

fn validate_vendor(vendor: &str) -> Result<()> {
    match vendor {
        "oci" | "gcp" | "cf" | "wasabi" => Ok(()),
        other => bail!("unsupported vendor: {} (oci|gcp|cf|wasabi)", other),
    }
}

fn print_help() {
    eprintln!(
        "import_csv — platform vendor cost CSV import\n\
\n\
  cargo run -p c35_mod_platform --example import_csv -- \\\n\
    --vendor cf --path invoice.csv \\\n\
    --period-start 2026-09-01 --period-end 2026-09-30 \\\n\
    [--category other] [--finalize] [--dry-run]\n\
\n\
CSV columns: sku, description, amount, currency, category (flexible headers).\n\
Requires DATABASE_URL or YB_* env (see server_ai/.env.local)."
    );
}
