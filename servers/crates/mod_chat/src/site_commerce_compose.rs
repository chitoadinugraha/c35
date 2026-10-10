//! Home POS / site commerce compose helpers (steer away from web.search on store data).

pub const SITE_QUERY_FORCE_INSTS: &[&str] = &[
    "inst.site.report",
    "inst.site.tx_browse",
    "inst.site.top_products",
    "inst.site.period_compare",
    "inst.site.compare",
    "inst.site.stock_report",
];

const READ_KEYWORDS: &[&str] = &[
    "omzet",
    "omset",
    "untung",
    "laba",
    "keuntungan",
    "transaksi",
    "penjualan",
    "pendapatan",
    "terlaris",
    "paling laku",
    "top product",
    "stok",
    "stock",
    "kartu stok",
    "mutasi stok",
    "daftar transaksi",
    "jumlah transaksi",
    "total transaksi",
    "profit",
    "sales today",
    "revenue",
    "dibanding",
    "vs kemarin",
    "bandingkan",
];

/// User text looks like a readonly POS / site report (not generic web).
pub fn site_commerce_read_intent(text: &str) -> bool {
    let lower = text.trim().to_lowercase();
    if lower.is_empty() {
        return false;
    }
    READ_KEYWORDS.iter().any(|k| lower.contains(k))
}

pub fn site_commerce_inst_matched(matched_ids: &[String]) -> bool {
    matched_ids
        .iter()
        .any(|id| SITE_QUERY_FORCE_INSTS.iter().any(|want| *want == id.as_str()))
        || matched_ids.iter().any(|id| id == "inst.site.commerce")
}

/// Do not force-feed web.search on general topic when the turn is site commerce.
pub fn site_commerce_suppress_general_web(text: &str, matched_ids: &[String]) -> bool {
    if matched_ids
        .iter()
        .any(|id| SITE_QUERY_FORCE_INSTS.iter().any(|want| *want == id.as_str()))
    {
        return true;
    }
    site_commerce_inst_matched(matched_ids) && site_commerce_read_intent(text)
}

pub fn site_commerce_suppress_web_tool_call(text: &str, matched_ids: &[String]) -> bool {
    site_commerce_suppress_general_web(text, matched_ids)
}

pub fn site_commerce_skip_web_prefetch(text: &str, matched_ids: &[String]) -> bool {
    site_commerce_suppress_general_web(text, matched_ids)
}

/// Ensure `site.query.run` is force-included when a site is in context and text is POS-read.
pub fn site_commerce_extra_tool_include(
    text: &str,
    matched_ids: &[String],
    has_site_context: bool,
) -> Vec<String> {
    if !has_site_context || !site_commerce_read_intent(text) {
        return vec![];
    }
    if matched_ids
        .iter()
        .any(|id| SITE_QUERY_FORCE_INSTS.iter().any(|want| *want == id.as_str()))
    {
        return vec![];
    }
    vec!["site.query.run".into()]
}

pub fn site_commerce_extra_tool_exclude(text: &str, matched_ids: &[String]) -> Vec<String> {
    if site_commerce_suppress_general_web(text, matched_ids) {
        return vec!["web.search".into(), "web.visit".into()];
    }
    vec![]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn read_intent_total_transaksi() {
        assert!(site_commerce_read_intent("berapa total transaksi hari ini"));
    }

    #[test]
    fn suppress_web_for_commerce_topic_and_transaksi() {
        let ids = vec!["inst.site.commerce".into(), "inst.web_search".into()];
        assert!(site_commerce_suppress_web_tool_call("berapa total transaksi hari ini", &ids));
    }
}
