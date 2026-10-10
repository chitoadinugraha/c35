use c35_mod_site::TxBrowseReport;

fn locale_id(locale: &str) -> bool {
    locale.trim().to_ascii_lowercase().starts_with("id")
}

fn format_idr(amount: i64) -> String {
    let s = amount.to_string();
    let mut out = String::new();
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    for (i, c) in chars.iter().enumerate() {
        if i > 0 && (len - i) % 3 == 0 {
            out.push('.');
        }
        out.push(*c);
    }
    out
}

pub fn tx_browse_plain_error(key: &str, locale: &str) -> String {
    let id = locale_id(locale);
    match key {
        "no_site" => {
            if id {
                "Tidak ada toko untuk menampilkan transaksi.".into()
            } else {
                "No site to list transactions for.".into()
            }
        }
        _ => {
            if id {
                "Tidak bisa memuat daftar transaksi.".into()
            } else {
                "Could not load the transaction list.".into()
            }
        }
    }
}

pub fn tx_browse_coach_fallback(report: &TxBrowseReport, locale: &str) -> String {
    let id = locale_id(locale);
    let rev = format_idr(report.total_revenue);
    let site = report.primary_site_name.trim();
    if id {
        if site.is_empty() {
            format!(
                "{}: {} transaksi, omzet Rp {}.",
                report.range_label,
                report.row_count,
                rev
            )
        } else {
            format!(
                "{} di {}: {} transaksi, omzet Rp {}.",
                report.range_label,
                site,
                report.row_count,
                rev
            )
        }
    } else if site.is_empty() {
        format!(
            "{}: {} transactions, revenue Rp {}.",
            report.range_label,
            report.row_count,
            rev
        )
    } else {
        format!(
            "{} at {}: {} transactions, revenue Rp {}.",
            report.range_label,
            site,
            report.row_count,
            rev
        )
    }
}
