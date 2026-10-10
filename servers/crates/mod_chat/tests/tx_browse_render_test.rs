use c35_mod_chat::tx_browse_llm_payload;
use c35_mod_site::{TxBrowseDisplayRow, TxBrowseReport, TxBrowseStats};

fn sample_report() -> TxBrowseReport {
    TxBrowseReport {
        kind: "tx.sales_list".into(),
        title: "Transaksi · Gucicha · Hari ini".into(),
        headers: vec![],
        rows: (0..20).map(|i| vec![i.to_string()]).collect(),
        row_count: 20,
        truncated: true,
        total_revenue: 350_000,
        range_key: "today".into(),
        range_label: "Hari ini".into(),
        single_site: true,
        primary_site_name: "Gucicha".into(),
        show_site_column: false,
        open_only: false,
        display: vec![TxBrowseDisplayRow {
            tx_id: "1".into(),
            time: "19:30".into(),
            total: 35_000,
            label: "Penjualan".into(),
            status: None,
            site_name: None,
            unpaid: None,
        }],
        stats: TxBrowseStats {
            avg_ticket: 35_000,
            max_total: 35_000,
            min_total: 35_000,
        },
    }
}

#[test]
fn llm_payload_has_no_full_rows() {
    let report = sample_report();
    let llm = tx_browse_llm_payload(&report, &[]);
    assert!(llm.get("rows").is_none());
    let preview = llm.get("preview").and_then(|v| v.as_array()).unwrap();
    assert!(preview.len() <= 5);
    assert_eq!(llm.get("row_count").and_then(|v| v.as_i64()), Some(20));
}
