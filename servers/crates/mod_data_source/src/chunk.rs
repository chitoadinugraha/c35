use serde_json::{json, Value};

use crate::config::EMBED_MIN_CHARS;
use crate::csv::parse_csv;

pub struct ChunkSpec {
    pub chunk_key: String,
    pub content: String,
    pub meta: Value,
}

pub fn embed_normalize(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut prev_space = false;
    for ch in s.chars() {
        let is_ws = ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\u{00A0}';
        if is_ws {
            if !out.is_empty() && !prev_space {
                out.push(' ');
                prev_space = true;
            }
        } else {
            out.push(ch);
            prev_space = false;
        }
    }
    if out.ends_with(' ') {
        out.pop();
    }
    out
}

pub fn snapshot_hash(csv: &str) -> String {
    blake3::hash(csv.as_bytes()).to_hex().to_string()
}

pub fn chunk_content_hash(content: &str) -> String {
    blake3::hash(embed_normalize(content).as_bytes())
        .to_hex()
        .to_string()
}

pub fn chunk_embed_eligible(content: &str) -> bool {
    embed_normalize(content).chars().count() >= EMBED_MIN_CHARS
}

pub fn sheet_csv_chunk_rows(csv: &str, tab: &str) -> (Vec<ChunkSpec>, usize) {
    let rows = parse_csv(csv);
    if rows.is_empty() {
        return (Vec::new(), 0);
    }
    let header = rows[0].clone();
    let mut chunks = vec![ChunkSpec {
        chunk_key: "header".into(),
        content: format!("Columns: {}", header.join(", ")),
        meta: json!({ "row": 0, "tab": tab }),
    }];
    let data_count = rows.len().saturating_sub(1);
    for (i, row) in rows.iter().skip(1).enumerate() {
        let row_num = i + 2;
        let parts: Vec<String> = header
            .iter()
            .zip(row.iter().chain(std::iter::repeat(&String::new())))
            .map(|(h, c)| format!("{}: {}", h.trim(), c.trim()))
            .collect();
        chunks.push(ChunkSpec {
            chunk_key: format!("row:{row_num}"),
            content: parts.join(" | "),
            meta: json!({ "row": row_num, "tab": tab }),
        });
    }
    (chunks, data_count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sheet_chunks_include_header_and_rows() {
        let csv = "Produk,Harga\nAyam Goreng,10\nNasi Goreng,24";
        let (chunks, data_rows) = sheet_csv_chunk_rows(csv, "Sheet1");
        assert_eq!(data_rows, 2);
        assert_eq!(chunks.len(), 3);
        assert!(chunks[0].content.contains("Produk"));
        assert!(chunks[1].content.contains("Ayam Goreng"));
    }

    #[test]
    fn snapshot_hash_stable() {
        let a = snapshot_hash("a,b\n1,2");
        let b = snapshot_hash("a,b\n1,2");
        assert_eq!(a, b);
        assert_ne!(a, snapshot_hash("a,b\n1,3"));
    }
}
