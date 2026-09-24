use super::fingerprint::food_name_label;
use super::types::{ConsumptionGlance, ConsumptionItem};

pub fn food_log_headline(saved: bool, duplicate: bool, items: &[ConsumptionItem], kcal: i32, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let name = food_name_label(items, locale);
    if !saved && duplicate {
        return if id {
            format!("Kamu sudah catat {name} hari ini ({kcal} kalori)")
        } else {
            format!("You already logged {name} today ({kcal} kcal)")
        };
    }
    if saved {
        return if id {
            format!("Konsumsi {name} sudah tercatat.")
        } else {
            format!("{name} logged.")
        };
    }
    if id {
        format!("{name} terlihat enak ({kcal} kalori)")
    } else {
        format!("{name} looks tasty ({kcal} kcal)")
    }
}

fn food_observation(items: &[ConsumptionItem], locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let name = food_name_label(items, locale);
    let fat: i32 = items.iter().map(|i| ((i.fat as f32) * i.qty).round() as i32).sum();
    let protein: i32 = items.iter().map(|i| ((i.protein as f32) * i.qty).round() as i32).sum();
    if items.len() > 1 {
        return if id {
            format!("{name} — beberapa item terlihat enak. Total lemak sekitar {fat}g.")
        } else {
            format!("{name} — a few tasty-looking items. About {fat}g fat total.")
        };
    }
    if fat <= 10 {
        return if id {
            format!("{name} kelihatan enak, lemaknya juga terlihat ringan ({fat}g).")
        } else {
            format!("{name} looks tasty, and the fat seems pretty light ({fat}g).")
        };
    }
    if fat >= 25 {
        return if id {
            format!("{name} kelihatan menggoda — lemaknya agak tinggi ({fat}g), nikmati secukupnya ya.")
        } else {
            format!("{name} looks indulgent — fat's a bit high ({fat}g), enjoy in moderation.")
        };
    }
    if protein >= 20 {
        return if id {
            format!("{name} kelihatan enak dan proteinnya lumayan ({protein}g) — bagus buat kenyang.")
        } else {
            format!("{name} looks good and packs decent protein ({protein}g) — should keep you full.")
        };
    }
    if id {
        format!("{name} kelihatan enak — porsinya pas untuk sekali makan.")
    } else {
        format!("{name} looks tasty — a reasonable portion for one meal.")
    }
}

pub fn food_log_coach(items: &[ConsumptionItem], after: i32, goal: i32, duplicate_logged_again: bool, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    let observation = food_observation(items, locale);
    if duplicate_logged_again {
        return if id {
            format!("{observation} Catatan kedua hari ini — jangan lupa hitung total kalorinya ya.")
        } else {
            format!("{observation} Logged again today — keep an eye on your running total.")
        };
    }
    let pct = if goal > 0 {
        (after as f32 / goal as f32 * 100.0).round() as i32
    } else {
        0
    };
    if after > goal {
        return if id {
            format!("{observation} Hari ini sudah {pct}% dari target kalori — pelan-pelan ya.")
        } else {
            format!("{observation} You're at {pct}% of today's calorie goal — easy does it.")
        };
    }
    if pct >= 85 {
        return if id {
            format!("{observation} Hampir mentok target hari ini — sisanya pilih yang ringan ya.")
        } else {
            format!("{observation} You're close to today's goal — keep the rest of the day light.")
        };
    }
    observation
}

pub fn today_recap_coach(glance: &ConsumptionGlance, locale: &str) -> String {
    let id = locale.to_lowercase().starts_with("id");
    if glance.meals_logged == 0 {
        return if id {
            "Belum ada catatan makan hari ini — mulai log biar gampang pantau.".into()
        } else {
            "No meals logged yet today — start tracking to stay on top of it.".into()
        };
    }
    let pct = if glance.calorie_goal > 0 {
        (glance.calories as f32 / glance.calorie_goal as f32 * 100.0).round() as i32
    } else {
        0
    };
    if glance.calories > glance.calorie_goal {
        return if id {
            format!("Hari ini sudah {pct}% target kalori — sisanya pilih yang ringan ya.")
        } else {
            format!("You're at {pct}% of today's calorie goal — ease up for the rest of the day.")
        };
    }
    if pct >= 85 {
        return if id {
            "Mantap, hampir mentok target — sisanya jangan kebablasan ya.".into()
        } else {
            "Nice progress — you're close to your goal, keep the rest light.".into()
        };
    }
    if id {
        format!(
            "Bagus! {} kali makan, {} kalori — masih {} kalori tersisa.",
            glance.meals_logged, glance.calories, glance.calories_remaining
        )
    } else {
        format!(
            "Looking good! {} meals, {} kcal — {} kcal left today.",
            glance.meals_logged, glance.calories, glance.calories_remaining
        )
    }
}
