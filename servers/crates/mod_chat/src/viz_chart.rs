//! Native chart blocks (`viz.chart`) for assistant messages — tool + ```chart fences.

use serde_json::{json, Value};

const MAX_LABELS: usize = 24;
const MAX_SERIES: usize = 4;
const KIND: &str = "viz.chart";

pub fn viz_chart_block_from_value(v: &Value) -> Result<Value, String> {
    let body = normalize_chart_body(v)?;
    Ok(json!({
        "kind": KIND,
        "collapsed": false,
        "body": body,
    }))
}

pub fn merge_assistant_charts(content: String, blocks_json: &str) -> (String, String) {
    let (stripped, extracted) = extract_chart_fences(&content);
    if extracted.is_empty() {
        return (content, blocks_json.to_string());
    }
    let mut arr = serde_json::from_str::<Vec<Value>>(blocks_json).unwrap_or_default();
    for block in extracted {
        arr.push(block);
    }
    let blocks = serde_json::to_string(&arr).unwrap_or_else(|_| blocks_json.to_string());
    (stripped.trim().to_string(), blocks)
}

/// Strip ```chart … ``` fences and return validated blocks.
pub fn extract_chart_fences(content: &str) -> (String, Vec<Value>) {
    let mut out = String::new();
    let mut blocks = Vec::new();
    let mut i = 0;
    let bytes = content.as_bytes();
    let open = b"```chart";
    while i < bytes.len() {
        if bytes[i..].starts_with(open) {
            let mut j = i + open.len();
            while j < bytes.len() && bytes[j] != b'\n' && bytes[j] != b'\r' {
                j += 1;
            }
            while j < bytes.len() && (bytes[j] == b'\n' || bytes[j] == b'\r') {
                j += 1;
            }
            let close = content[j..].find("```");
            if let Some(rel) = close {
                let inner = content[j..j + rel].trim();
                if let Ok(v) = serde_json::from_str::<Value>(inner) {
                    if let Ok(block) = viz_chart_block_from_value(&v) {
                        blocks.push(block);
                    }
                }
                i = j + rel + 3;
                continue;
            }
        }
        out.push(bytes[i] as char);
        i += 1;
    }
    (out, blocks)
}

fn normalize_chart_body(v: &Value) -> Result<Value, String> {
    let chart_type = v
        .get("chart_type")
        .or_else(|| v.get("type"))
        .and_then(|x| x.as_str())
        .map(|s| s.trim().to_lowercase())
        .filter(|s| matches!(s.as_str(), "bar" | "line" | "pie"))
        .ok_or_else(|| "chart_type must be bar, line, or pie".to_string())?;

    let title = v
        .get("title")
        .and_then(|x| x.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .unwrap_or("")
        .to_string();

    let x_label = optional_label(v.get("x_label"));
    let y_label = optional_label(v.get("y_label"));

    let labels = v
        .get("labels")
        .and_then(|x| x.as_array())
        .ok_or_else(|| "labels array required".to_string())?;
    if labels.is_empty() || labels.len() > MAX_LABELS {
        return Err(format!("labels length must be 1..={MAX_LABELS}"));
    }
    let labels: Vec<String> = labels
        .iter()
        .map(|x| {
            x.as_str()
                .map(|s| s.trim())
                .filter(|s| !s.is_empty())
                .map(|s| s.to_string())
                .ok_or_else(|| "labels must be strings".to_string())
        })
        .collect::<Result<Vec<_>, _>>()?;

    let series_raw = v
        .get("series")
        .and_then(|x| x.as_array())
        .ok_or_else(|| "series array required".to_string())?;
    if series_raw.is_empty() || series_raw.len() > MAX_SERIES {
        return Err(format!("series length must be 1..={MAX_SERIES}"));
    }

    let mut series = Vec::with_capacity(series_raw.len());
    for item in series_raw {
        let name = item
            .get("name")
            .and_then(|x| x.as_str())
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
            .unwrap_or("Series")
            .to_string();
        let values = item
            .get("values")
            .and_then(|x| x.as_array())
            .ok_or_else(|| "each series needs values array".to_string())?;
        if values.len() != labels.len() {
            return Err("each series values length must match labels length".to_string());
        }
        let mut nums = Vec::with_capacity(values.len());
        for n in values {
            let f = n
                .as_f64()
                .or_else(|| n.as_i64().map(|i| i as f64))
                .or_else(|| n.as_u64().map(|u| u as f64))
                .ok_or_else(|| "values must be numbers".to_string())?;
            if !f.is_finite() {
                return Err("values must be finite numbers".to_string());
            }
            nums.push(f);
        }
        series.push(json!({ "name": name, "values": nums }));
    }

    if chart_type == "pie" && labels.len() > 8 {
        return Err("pie charts allow at most 8 labels".to_string());
    }

    Ok(json!({
        "chart_type": chart_type,
        "title": title,
        "x_label": x_label,
        "y_label": y_label,
        "labels": labels,
        "series": series,
    }))
}

fn optional_label(v: Option<&Value>) -> String {
    v.and_then(|x| x.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .unwrap_or("")
        .to_string()
}

pub fn viz_chart_llm_summary(body: &Value) -> Value {
    let title = body.get("title").and_then(|v| v.as_str()).unwrap_or("");
    let chart_type = body.get("chart_type").and_then(|v| v.as_str()).unwrap_or("");
    let labels = body
        .get("labels")
        .and_then(|v| v.as_array())
        .map(|a| a.len())
        .unwrap_or(0);
    json!({
        "chart_type": chart_type,
        "title": title,
        "point_count": labels,
        "note": "Chart block attached; do not repeat the numeric series in prose.",
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_block_from_args() {
        let v = json!({
            "chart_type": "line",
            "title": "Revenue",
            "labels": ["Jan", "Feb"],
            "series": [{ "name": "IDR", "values": [1.0, 2.0] }]
        });
        let block = viz_chart_block_from_value(&v).unwrap();
        assert_eq!(block["kind"], KIND);
        assert_eq!(block["body"]["chart_type"], "line");
    }

    #[test]
    fn extracts_fence() {
        let md = "Summary here.\n\n```chart\n{\"chart_type\":\"bar\",\"labels\":[\"A\"],\"series\":[{\"name\":\"x\",\"values\":[3]}]}\n```\nTail.";
        let (text, blocks) = extract_chart_fences(md);
        assert!(!text.contains("```chart"));
        assert_eq!(blocks.len(), 1);
        assert_eq!(blocks[0]["body"]["chart_type"], "bar");
    }

    #[test]
    fn merge_appends_blocks() {
        let (text, blocks) = merge_assistant_charts(
            "```chart\n{\"chart_type\":\"pie\",\"labels\":[\"A\",\"B\"],\"series\":[{\"name\":\"Share\",\"values\":[60,40]}]}\n```".into(),
            "[]",
        );
        assert!(text.is_empty());
        let arr: Vec<Value> = serde_json::from_str(&blocks).unwrap();
        assert_eq!(arr.len(), 1);
    }
}
