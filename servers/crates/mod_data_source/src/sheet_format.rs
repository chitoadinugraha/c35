//! Google Sheets API `batchUpdate` formatting (borders, alignment, number formats).

use anyhow::{bail, Context, Result};
use serde_json::{json, Value};

use crate::google_sheet::{google_sheet_metadata, sheet_a1_range, sheet_tab_name, GoogleSheetConfig};

pub async fn google_sheet_format_range(
    http: &reqwest::Client,
    cfg: &GoogleSheetConfig,
    range: &str,
    format: &Value,
) -> Result<Value> {
    let range = range.trim();
    if range.is_empty() {
        bail!("range is required (e.g. A1:C1)");
    }
    let tab = sheet_tab_name(cfg);
    let full_range = if range.contains('!') {
        range.to_string()
    } else {
        sheet_a1_range(&tab, range)
    };
    let sheet_id = resolve_sheet_id(http, cfg).await?;
    let grid = parse_a1_range_to_grid(&full_range, sheet_id)?;
    let requests = build_format_requests(&grid, format)?;
    if requests.is_empty() {
        bail!("no format options provided (bold, borders, horizontal_alignment, number_format, …)");
    }
    let body = json!({ "requests": requests });
    let res = crate::google_sheet::apply_spreadsheets_batch_update(&cfg.spreadsheet_id, body).await?;
    Ok(json!({
        "ok": true,
        "spreadsheet_id": cfg.spreadsheet_id,
        "tab": tab,
        "range": full_range,
        "sheet_id": sheet_id,
        "result": res,
    }))
}

async fn resolve_sheet_id(http: &reqwest::Client, cfg: &GoogleSheetConfig) -> Result<i64> {
    let want_gid = cfg.gid.trim();
    let (_title, tabs) = google_sheet_metadata(http, &cfg.spreadsheet_id).await?;
    if !want_gid.is_empty() && want_gid != "0" {
        for (_name, gid) in &tabs {
            if gid == want_gid {
                return gid.parse().context("parse sheet gid as sheetId");
            }
        }
    }
    if let Some((_name, gid)) = tabs.first() {
        return gid.parse().context("parse default sheet gid");
    }
    Ok(0)
}

#[derive(Clone, Debug)]
pub struct GridRange {
    pub sheet_id: i64,
    pub start_row: u32,
    pub end_row: u32,
    pub start_col: u32,
    pub end_col: u32,
}

fn parse_a1_range_to_grid(full_range: &str, sheet_id: i64) -> Result<GridRange> {
    let a1 = full_range
        .split('!')
        .next_back()
        .unwrap_or(full_range)
        .trim();
    let parts: Vec<&str> = a1.split(':').collect();
    let start = parse_cell_ref(parts.first().context("empty range")?)?;
    let end = if parts.len() > 1 {
        parse_cell_ref(parts[1])?
    } else {
        start
    };
    Ok(GridRange {
        sheet_id,
        start_row: start.row,
        end_row: end.row + 1,
        start_col: start.col,
        end_col: end.col + 1,
    })
}

#[derive(Clone, Copy)]
struct CellRef {
    row: u32,
    col: u32,
}

fn parse_cell_ref(s: &str) -> Result<CellRef> {
    let s = s.trim().to_uppercase();
    if s.is_empty() {
        bail!("empty cell reference");
    }
    let split = s
        .chars()
        .position(|c| c.is_ascii_digit())
        .context("invalid cell reference")?;
    let col_part = &s[..split];
    let row_part = &s[split..];
    let row: u32 = row_part.parse().context("invalid row number")?;
    if row < 1 {
        bail!("row must be >= 1");
    }
    let col = col_letters_to_index(col_part)?;
    Ok(CellRef {
        row: row - 1,
        col,
    })
}

fn col_letters_to_index(letters: &str) -> Result<u32> {
    if letters.is_empty() {
        bail!("empty column letters");
    }
    let mut n: u32 = 0;
    for c in letters.chars() {
        if !c.is_ascii_uppercase() {
            bail!("invalid column letter");
        }
        n = n * 26 + (c as u32 - b'A' as u32 + 1);
    }
    Ok(n - 1)
}

fn grid_range_json(g: &GridRange) -> Value {
    json!({
        "sheetId": g.sheet_id,
        "startRowIndex": g.start_row,
        "endRowIndex": g.end_row,
        "startColumnIndex": g.start_col,
        "endColumnIndex": g.end_col,
    })
}

fn border_style_json(style: &str) -> Value {
    let s = style.trim().to_uppercase();
    let st = match s.as_str() {
        "DOTTED" => "DOTTED",
        "DASHED" => "DASHED",
        "SOLID_MEDIUM" => "SOLID_MEDIUM",
        "SOLID_THICK" => "SOLID_THICK",
        _ => "SOLID",
    };
    json!({ "style": st, "width": 1, "color": { "red": 0.0, "green": 0.0, "blue": 0.0 } })
}

pub fn build_format_requests(grid: &GridRange, format: &Value) -> Result<Vec<Value>> {
    let mut requests = Vec::new();
    let mut user_fmt = json!({});
    let mut fields: Vec<String> = Vec::new();

    if format.get("bold").and_then(|v| v.as_bool()) == Some(true) {
        user_fmt["textFormat"] = json!({ "bold": true });
        fields.push("userEnteredFormat.textFormat.bold".into());
    }
    if format.get("italic").and_then(|v| v.as_bool()) == Some(true) {
        merge_text_format(&mut user_fmt, json!({ "italic": true }));
        fields.push("userEnteredFormat.textFormat.italic".into());
    }
    if format.get("underline").and_then(|v| v.as_bool()) == Some(true) {
        merge_text_format(&mut user_fmt, json!({ "underline": true }));
        fields.push("userEnteredFormat.textFormat.underline".into());
    }

    if let Some(align) = format.get("horizontal_alignment").and_then(|v| v.as_str()) {
        let a = align.trim().to_uppercase();
        let h = match a.as_str() {
            "LEFT" => "LEFT",
            "RIGHT" => "RIGHT",
            "CENTER" => "CENTER",
            other => bail!("horizontal_alignment must be LEFT, CENTER, or RIGHT (got {other})"),
        };
        user_fmt["horizontalAlignment"] = json!(h);
        fields.push("userEnteredFormat.horizontalAlignment".into());
    }
    if let Some(align) = format.get("vertical_alignment").and_then(|v| v.as_str()) {
        let a = align.trim().to_uppercase();
        let v = match a.as_str() {
            "TOP" => "TOP",
            "BOTTOM" => "BOTTOM",
            "MIDDLE" => "MIDDLE",
            other => bail!("vertical_alignment must be TOP, MIDDLE, or BOTTOM (got {other})"),
        };
        user_fmt["verticalAlignment"] = json!(v);
        fields.push("userEnteredFormat.verticalAlignment".into());
    }
    if format.get("wrap").and_then(|v| v.as_bool()) == Some(true) {
        user_fmt["wrapStrategy"] = json!("WRAP");
        fields.push("userEnteredFormat.wrapStrategy".into());
    } else if format.get("wrap").and_then(|v| v.as_bool()) == Some(false) {
        user_fmt["wrapStrategy"] = json!("CLIP");
        fields.push("userEnteredFormat.wrapStrategy".into());
    }

    if let Some(nf) = number_format_json(format) {
        user_fmt["numberFormat"] = nf;
        fields.push("userEnteredFormat.numberFormat".into());
    }

    if !fields.is_empty() {
        let fields_joined = fields.join(",");
        requests.push(json!({
            "repeatCell": {
                "range": grid_range_json(grid),
                "cell": { "userEnteredFormat": user_fmt },
                "fields": fields_joined,
            }
        }));
    }

    if let Some(border_req) = build_border_request(grid, format) {
        requests.push(border_req);
    }

    Ok(requests)
}

fn merge_text_format(user_fmt: &mut Value, patch: Value) {
    if let Some(obj) = user_fmt.get_mut("textFormat").and_then(|v| v.as_object_mut()) {
        if let Some(p) = patch.as_object() {
            for (k, v) in p {
                obj.insert(k.clone(), v.clone());
            }
        }
    } else {
        user_fmt["textFormat"] = patch;
    }
}

fn number_format_json(format: &Value) -> Option<Value> {
    if let Some(pat) = format.get("number_format_pattern").and_then(|v| v.as_str()) {
        let p = pat.trim();
        if !p.is_empty() {
            return Some(json!({ "type": "NUMBER", "pattern": p }));
        }
    }
    let typ = format
        .get("number_format")
        .or_else(|| format.get("number_format_type"))
        .and_then(|v| v.as_str())
        .map(|s| s.trim().to_uppercase());
    let typ = typ?;
    let pattern = format
        .get("number_format_pattern")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty());
    match typ.as_str() {
        "TEXT" => Some(json!({ "type": "TEXT" })),
        "NUMBER" => Some(json!({
            "type": "NUMBER",
            "pattern": pattern.unwrap_or("#,##0.########")
        })),
        "CURRENCY" => Some(json!({
            "type": "CURRENCY",
            "pattern": pattern.unwrap_or("Rp#,##0")
        })),
        "PERCENT" => Some(json!({
            "type": "PERCENT",
            "pattern": pattern.unwrap_or("0.00%")
        })),
        "DATE" => Some(json!({ "type": "DATE", "pattern": pattern.unwrap_or("yyyy-mm-dd") })),
        "TIME" => Some(json!({ "type": "TIME", "pattern": pattern.unwrap_or("hh:mm:ss") })),
        "DATE_TIME" => Some(json!({
            "type": "DATE_TIME",
            "pattern": pattern.unwrap_or("yyyy-mm-dd hh:mm:ss")
        })),
        "SCIENTIFIC" => Some(json!({ "type": "SCIENTIFIC", "pattern": pattern.unwrap_or("0.00E+00") })),
        _ => None,
    }
}

fn build_border_request(grid: &GridRange, format: &Value) -> Option<Value> {
    let borders = format.get("borders").and_then(|v| v.as_str()).map(|s| s.to_string());
    let borders = borders?;
    let preset = borders.trim().to_lowercase();
    if preset == "none" || preset == "clear" {
        return Some(json!({
            "updateBorders": {
                "range": grid_range_json(grid),
                "top": { "style": "NONE" },
                "bottom": { "style": "NONE" },
                "left": { "style": "NONE" },
                "right": { "style": "NONE" },
                "innerHorizontal": { "style": "NONE" },
                "innerVertical": { "style": "NONE" },
            }
        }));
    }
    let style_key = format
        .get("border_style")
        .and_then(|v| v.as_str())
        .unwrap_or("SOLID");
    let edge = border_style_json(style_key);
    let mut top = edge.clone();
    let mut bottom = edge.clone();
    let mut left = edge.clone();
    let mut right = edge.clone();
    let mut inner_h = edge.clone();
    let mut inner_v = edge.clone();
    match preset.as_str() {
        "all" => {}
        "outer" => {
            inner_h = json!({ "style": "NONE" });
            inner_v = json!({ "style": "NONE" });
        }
        "inner" => {
            top = json!({ "style": "NONE" });
            bottom = json!({ "style": "NONE" });
            left = json!({ "style": "NONE" });
            right = json!({ "style": "NONE" });
        }
        _ => return None,
    }
    Some(json!({
        "updateBorders": {
            "range": grid_range_json(grid),
            "top": top,
            "bottom": bottom,
            "left": left,
            "right": right,
            "innerHorizontal": inner_h,
            "innerVertical": inner_v,
        }
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_single_cell() {
        let g = parse_a1_range_to_grid("Sheet1!B2", 9).unwrap();
        assert_eq!(g.sheet_id, 9);
        assert_eq!(g.start_row, 1);
        assert_eq!(g.start_col, 1);
        assert_eq!(g.end_row, 2);
        assert_eq!(g.end_col, 2);
    }

    #[test]
    fn builds_bold_and_border() {
        let g = GridRange {
            sheet_id: 0,
            start_row: 0,
            end_row: 1,
            start_col: 0,
            end_col: 3,
        };
        let reqs = build_format_requests(
            &g,
            &json!({
                "bold": true,
                "horizontal_alignment": "CENTER",
                "borders": "all",
                "number_format": "CURRENCY"
            }),
        )
        .unwrap();
        assert_eq!(reqs.len(), 2);
    }
}
