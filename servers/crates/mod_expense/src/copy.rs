use super::fingerprint::item_name_label;
use super::types::{ExpenseGlance, ExpenseItem};

pub fn format_idr_minor(amount: i64) -> String {
    let s = amount.to_string();
    let mut out = String::new();
    let len = s.len();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (len - i) % 3 == 0 {
            out.push('.');
        }
        out.push(ch);
    }
    format!("Rp {out}")
}

pub fn expense_log_headline(saved: bool, duplicate: bool, items: &[ExpenseItem], total: i64, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let name = item_name_label(items, locale);
    if !saved && duplicate {
        return if id {
            format!("Kamu sudah catat {name} hari ini ({})", format_idr_minor(total))
        } else {
            format!("You already logged {name} today ({})", format_idr_minor(total))
        };
    }
    if saved {
        return name;
    }
    if id {
        format!("{name} ({})", format_idr_minor(total))
    } else {
        format!("{name} ({})", format_idr_minor(total))
    }
}

pub fn expense_log_coach(saved: bool, total: i64, after: i64, duplicate: bool, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    if !saved {
        return String::new();
    }
    if duplicate {
        return if id {
            "Catatan kedua hari ini — cek total pengeluaranmu ya.".into()
        } else {
            "Logged again today — keep an eye on your running total.".into()
        };
    }
    if id {
        format!("Tercatat {}. Total hari ini {}.", format_idr_minor(total), format_idr_minor(after))
    } else {
        format!("Logged {}. Today's total {}.", format_idr_minor(total), format_idr_minor(after))
    }
}

pub fn expense_summary_coach(glance: &ExpenseGlance, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    if glance.tx_count == 0 {
        return if id {
            "Belum ada pengeluaran tercatat — mulai catat biar gampang pantau.".into()
        } else {
            "No spending logged yet — start tracking to stay on top of it.".into()
        };
    }
    if id {
        format!(
            "{} dari {} pembelian",
            format_idr_minor(glance.total_minor),
            glance.tx_count
        )
    } else {
        format!(
            "{} across {} purchases",
            format_idr_minor(glance.total_minor),
            glance.tx_count
        )
    }
}
