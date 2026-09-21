use c35_proto::{ReqDevicePairRegister, ResDevicePairRegister};
use c35_store::snowflake_id;
use chrono::Utc;
use rand::{Rng, RngCore};
use serde_json::json;
use sqlx::PgPool;

const PAIR_CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
const PAIR_TTL_MS: i64 = 300_000;
const MAX_CODE_RETRIES: usize = 10;

pub async fn device_pair_register(
    pool: &PgPool,
    req: ReqDevicePairRegister,
) -> Result<ResDevicePairRegister, String> {
    let device_name = req.device_name.trim();
    if device_name.is_empty() {
        return Err("device_name required".into());
    }
    let device_type = {
        let t = req.device_type.trim();
        if t.is_empty() {
            "windows"
        } else {
            t
        }
    };

    let now_ms = Utc::now().timestamp_millis();
    let pairing_expires_ms = now_ms + PAIR_TTL_MS;

    for _ in 0..MAX_CODE_RETRIES {
        let (code, display) = pairing_code_generate();
        let device_secret = device_secret_generate();

        let collision = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT 1
            FROM ai.identity
            WHERE deleted_ts IS NULL
              AND meta->>'pairing_code' = $1
              AND COALESCE((meta->>'pairing_expires_ms')::bigint, 0) > $2
            LIMIT 1
            "#,
        )
        .bind(&code)
        .bind(now_ms)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;

        if collision.is_some() {
            continue;
        }

        let id = snowflake_id();
        let meta = json!({
            "pairing_code": code,
            "device_secret": device_secret,
            "pairing_expires_ms": pairing_expires_ms,
        });

        sqlx::query(
            r#"
            INSERT INTO ai.identity (id, kind, type, name, owner_iid, meta, created_ts, updated_ts)
            VALUES ($1, 'remote', $2, $3, NULL, $4, NOW(), NOW())
            "#,
        )
        .bind(id)
        .bind(device_type)
        .bind(device_name)
        .bind(&meta)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;

        return Ok(ResDevicePairRegister {
            code: display,
            device_secret,
            expires_in_sec: 300,
        });
    }

    Err("failed to generate unique pairing code".into())
}

fn pairing_code_generate() -> (String, String) {
    let code: String = (0..10)
        .map(|_| {
            let idx = rand::rngs::OsRng.gen_range(0..PAIR_CHARS.len());
            PAIR_CHARS[idx] as char
        })
        .collect();
    let display = format!("{}-{}", &code[..5], &code[5..]);
    (code, display)
}

fn device_secret_generate() -> String {
    format!("sec_{}", random_hex())
}

fn random_hex() -> String {
    let mut rng_bytes = [0u8; 32];
    rand::rngs::OsRng.fill_bytes(&mut rng_bytes);
    blake3::hash(&rng_bytes).to_hex().to_string()
}
