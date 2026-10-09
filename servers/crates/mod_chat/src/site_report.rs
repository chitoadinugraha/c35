//! Parse profit / sales summary questions (not transaction lists or period compare).

pub struct SiteReportIntent {
    pub query_id: &'static str,
    pub range: String,
}

pub fn site_report_parse(text: &str) -> Option<SiteReportIntent> {
    let lower = text.trim().to_lowercase();
    if lower.is_empty() {
        return None;
    }
    if lower.contains("dibanding")
        || lower.contains(" vs ")
        || lower.contains("banding")
        || lower.contains("compare")
    {
        return None;
    }
    if lower.contains("daftar transaksi")
        || lower.contains("apa saja transaksi")
        || lower.contains("list transaksi")
        || lower.contains("transaksi terakhir")
        || lower.contains("nota terakhir")
        || (lower.contains("transaksi") && !lower.contains("berapa transaksi"))
    {
        return None;
    }
    if lower.contains("stok")
        || lower.contains("stock")
        || lower.contains("kartu stok")
        || lower.contains("daftar stok")
    {
        return None;
    }

    let profit = lower.contains("untung")
        || lower.contains("laba")
        || lower.contains("keuntungan")
        || lower.contains("profit");
    let sales = lower.contains("omzet")
        || lower.contains("penjualan")
        || lower.contains("pendapatan")
        || lower.contains("revenue")
        || lower.contains("berapa transaksi");
    if !profit && !sales {
        return None;
    }

    let query_id = if profit {
        "tx.profit_summary"
    } else {
        "tx.sales_summary"
    };

    let range = if lower.contains("kemarin") {
        "yesterday".to_string()
    } else if lower.contains("minggu ini") || lower.contains("this week") {
        "this_week".to_string()
    } else if lower.contains("bulan ini") || lower.contains("this month") {
        "this_month".to_string()
    } else {
        "today".to_string()
    };

    Some(SiteReportIntent { query_id, range })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_untung_hari_ini() {
        let i = site_report_parse("Berapa untung hari ini ?").unwrap();
        assert_eq!(i.query_id, "tx.profit_summary");
        assert_eq!(i.range, "today");
    }

    #[test]
    fn parses_omzet() {
        let i = site_report_parse("berapa omzet hari ini").unwrap();
        assert_eq!(i.query_id, "tx.sales_summary");
    }

    #[test]
    fn rejects_tx_browse() {
        assert!(site_report_parse("daftar transaksi hari ini").is_none());
    }

    #[test]
    fn rejects_period_compare() {
        assert!(site_report_parse("omzet hari ini dibanding kemarin").is_none());
    }
}
