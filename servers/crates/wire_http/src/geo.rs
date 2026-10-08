use axum::{
    extract::Query,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::get,
    Json, Router,
};
use c35_ctx::AppState;
use serde::Serialize;

const NOMINATIM_BASE: &str = "https://nominatim.openstreetmap.org";
const NOMINATIM_USER_AGENT: &str = "AlienAI/1.0 (https://alienai.id; ops@alienai.id)";

pub fn geo_router() -> Router<AppState> {
    Router::new()
        .route("/api/geo/search", get(handle_geo_search))
        .route("/api/geo/reverse", get(handle_geo_reverse))
}

#[derive(serde::Deserialize)]
struct GeoSearchQ {
    q: Option<String>,
}

#[derive(Serialize, Clone)]
struct SearchResult {
    lat: f64,
    lng: f64,
    label: String,
}

#[derive(Serialize)]
struct GeoSearchRes {
    results: Vec<SearchResult>,
}

async fn handle_geo_search(Query(q): Query<GeoSearchQ>) -> Response {
    let query = q.q.unwrap_or_default();
    match geo_search(&query, 5).await {
        Ok(results) => Json(GeoSearchRes { results }).into_response(),
        Err(e) => {
            tracing::warn!("[geo] search {:?}: {}", query, e);
            (
                StatusCode::BAD_GATEWAY,
                Json(serde_json::json!({ "error": "address search failed" })),
            )
                .into_response()
        }
    }
}

#[derive(serde::Deserialize)]
struct GeoReverseQ {
    lat: Option<String>,
    lng: Option<String>,
}

#[derive(Serialize)]
struct GeoReverseRes {
    lat: f64,
    lng: f64,
    label: String,
}

async fn handle_geo_reverse(Query(q): Query<GeoReverseQ>) -> Response {
    let lat = q.lat.as_deref().and_then(|s| s.parse::<f64>().ok());
    let lng = q.lng.as_deref().and_then(|s| s.parse::<f64>().ok());
    let (Some(lat), Some(lng)) = (lat, lng) else {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({ "error": "invalid coordinates" })),
        )
            .into_response();
    };
    match geo_reverse(lat, lng).await {
        Ok(label) => Json(GeoReverseRes { lat, lng, label }).into_response(),
        Err(e) => {
            tracing::warn!("[geo] reverse {:.6},{:.6}: {}", lat, lng, e);
            (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({ "error": "address not found" })),
            )
                .into_response()
        }
    }
}

async fn geo_search(query: &str, limit: usize) -> Result<Vec<SearchResult>, String> {
    let q = query.trim();
    if q.len() < 2 {
        return Ok(vec![]);
    }
    let limit = limit.clamp(1, 10);
    let out = geo_search_nominatim(q, limit, true).await?;
    if !out.is_empty() {
        return Ok(out);
    }
    geo_search_nominatim(q, limit, false).await
}

async fn geo_search_nominatim(query: &str, limit: usize, indonesia_only: bool) -> Result<Vec<SearchResult>, String> {
    let client = nominatim_client()?;
    let mut req = client
        .get(format!("{NOMINATIM_BASE}/search"))
        .header("Accept-Language", "id,en")
        .query(&[
            ("q", query),
            ("format", "json"),
            ("limit", &limit.to_string()),
            ("addressdetails", "0"),
        ]);
    if indonesia_only {
        req = req.query(&[("countrycodes", "id")]);
    }
    let res = req.send().await.map_err(|e| e.to_string())?;
    let body = read_nominatim_response(res).await?;
    let rows: Vec<serde_json::Value> = serde_json::from_slice(&body).map_err(|e| e.to_string())?;
    let mut out = Vec::with_capacity(rows.len());
    for row in rows {
        let lat = row.get("lat").and_then(|v| v.as_str()).and_then(|s| s.parse::<f64>().ok());
        let lng = row.get("lon").and_then(|v| v.as_str()).and_then(|s| s.parse::<f64>().ok());
        let label = row
            .get("display_name")
            .and_then(|v| v.as_str())
            .map(str::trim)
            .unwrap_or("")
            .to_string();
        if let (Some(lat), Some(lng)) = (lat, lng) {
            if !label.is_empty() {
                out.push(SearchResult { lat, lng, label });
            }
        }
    }
    Ok(out)
}

async fn geo_reverse(lat: f64, lng: f64) -> Result<String, String> {
    let client = nominatim_client()?;
    let lat_s = lat.to_string();
    let lng_s = lng.to_string();
    let res = client
        .get(format!("{NOMINATIM_BASE}/reverse"))
        .header("Accept-Language", "id,en")
        .query(&[("lat", lat_s.as_str()), ("lon", lng_s.as_str()), ("format", "json")])
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body = read_nominatim_response(res).await?;
    let row: serde_json::Value = serde_json::from_slice(&body).map_err(|e| e.to_string())?;
    let label = row
        .get("display_name")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or("")
        .to_string();
    if label.is_empty() {
        return Err("address not found".into());
    }
    Ok(label)
}

fn nominatim_client() -> Result<reqwest::Client, String> {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(12))
        .user_agent(NOMINATIM_USER_AGENT)
        .build()
        .map_err(|e| e.to_string())
}

async fn read_nominatim_response(res: reqwest::Response) -> Result<Vec<u8>, String> {
    let status = res.status();
    let body = res.bytes().await.map_err(|e| e.to_string())?;
    if !status.is_success() {
        return Err(format!(
            "nominatim status {}: {}",
            status.as_u16(),
            String::from_utf8_lossy(&body).trim()
        ));
    }
    Ok(body.to_vec())
}
