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

pub fn format_currency_minor(amount: i64, currency: &str) -> String {
    let cur = currency.trim().to_uppercase();
    match cur.as_str() {
        "IDR" | "" => format_idr_minor(amount),
        "USD" => {
            let dollars = amount / 100;
            let cents = (amount % 100).abs();
            format!("${dollars}.{cents:02}")
        }
        "EUR" => {
            let euros = amount / 100;
            let cents = (amount % 100).abs();
            format!("€{euros}.{cents:02}")
        }
        "GBP" => {
            let pounds = amount / 100;
            let pence = (amount % 100).abs();
            format!("£{pounds}.{pence:02}")
        }
        "SGD" => {
            let dollars = amount / 100;
            let cents = (amount % 100).abs();
            format!("S${dollars}.{cents:02}")
        }
        "MYR" => {
            let ringgit = amount / 100;
            let sen = (amount % 100).abs();
            format!("RM {ringgit}.{sen:02}")
        }
        "JPY" => {
            format!("¥{amount}")
        }
        other => {
            format!("{other} {amount}")
        }
    }
}

pub fn expense_chat_title(items: &[ExpenseItem], locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let name = item_name_label(items, locale);
    if id {
        format!("🧾 Belanja: {name}")
    } else {
        format!("🧾 Expense: {name}")
    }
}

pub fn expense_log_headline(
    saved: bool,
    duplicate: bool,
    items: &[ExpenseItem],
    total: i64,
    currency: &str,
    locale: &str,
) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let name = item_name_label(items, locale);
    let formatted = format_currency_minor(total, currency);
    if !saved && duplicate {
        return if id {
            format!("Kamu sudah catat {name} hari ini ({formatted})")
        } else {
            format!("You already logged {name} today ({formatted})")
        };
    }
    if saved {
        return name;
    }
    format!("{name} ({formatted})")
}

pub fn expense_log_coach(
    saved: bool,
    total: i64,
    after: i64,
    duplicate: bool,
    currency: &str,
    locale: &str,
) -> String {
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
    let formatted_total = format_currency_minor(total, currency);
    let formatted_after = format_currency_minor(after, currency);
    if id {
        format!("Tercatat {formatted_total}. Total hari ini {formatted_after}.")
    } else {
        format!("Logged {formatted_total}. Today's total {formatted_after}.")
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
    let formatted_total = format_currency_minor(glance.total_minor, &glance.currency);
    if id {
        format!(
            "{} dari {} pembelian",
            formatted_total,
            glance.tx_count
        )
    } else {
        format!(
            "{} across {} purchases",
            formatted_total,
            glance.tx_count
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_currency_minor() {
        assert_eq!(format_currency_minor(18000, "IDR"), "Rp 18.000");
        assert_eq!(format_currency_minor(1250, "USD"), "$12.50");
        assert_eq!(format_currency_minor(500, "EUR"), "€5.00");
        assert_eq!(format_currency_minor(320, "SGD"), "S$3.20");
        assert_eq!(format_currency_minor(1500, "JPY"), "¥1500");
    }
}
