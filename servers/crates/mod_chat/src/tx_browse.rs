pub struct TxBrowseIntent {
    pub query_id: &'static str,
    pub range: String,
    pub limit: i32,
    pub open_only: bool,
    pub state: Option<String>,
}

pub fn tx_browse_parse(text: &str) -> Option<TxBrowseIntent> {
    let lower = text.trim().to_lowercase();
    if lower.is_empty() {
        return None;
    }
    let browse = lower.contains("daftar transaksi")
        || lower.contains("apa saja transaksi")
        || lower.contains("list transaksi")
        || lower.contains("transaksi hari")
        || lower.contains("transaksi terakhir")
        || lower.contains("nota terakhir")
        || (lower.contains("transaksi") && lower.contains("hari ini"))
        || lower.contains("belum lunas")
        || (lower.contains("transaksi") && lower.contains("batal"));
    if !browse {
        return None;
    }
    let mut limit = 50i32;
    let parts = lower.split_whitespace().collect::<Vec<_>>();
    for tok in parts.windows(2) {
        if let Ok(n) = tok[0].parse::<i32>() {
            if tok[1].contains("transaksi") || tok[1].contains("nota") {
                limit = n.clamp(1, 200);
            }
        }
    }
    if lower.contains("terakhir") {
        limit = limit.min(10);
    }
    let range = if lower.contains("kemarin") {
        "yesterday".to_string()
    } else if lower.contains("minggu ini") {
        "this_week".to_string()
    } else if lower.contains("bulan ini") {
        "this_month".to_string()
    } else {
        "today".to_string()
    };
    let open_only = lower.contains("belum lunas") || lower.contains("belum bayar");
    let state = if lower.contains("batal") {
        Some("cancelled".to_string())
    } else {
        None
    };
    Some(TxBrowseIntent {
        query_id: "tx.sales_list",
        range,
        limit,
        open_only,
        state,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_daftar_hari_ini() {
        let i = tx_browse_parse("daftar transaksi hari ini").unwrap();
        assert_eq!(i.range, "today");
    }

    #[test]
    fn rejects_unrelated() {
        assert!(tx_browse_parse("berapa stok susu").is_none());
    }
}