//! Plan a chat-bot draft: purpose, instruction, sheet access, and the one missing question.

use serde_json::{json, Value};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SheetIn {
    pub url: String,
    pub name: String,
    pub tab: String,
    pub access_mode: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BotDraftInput {
    pub purpose: String,
    pub name: String,
    pub inst_base: String,
    pub bot_iid: i64,
    pub channel: String,
    pub activate: bool,
    pub web_search: bool,
    pub sheets: Vec<SheetIn>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PlannedSheet {
    pub url: String,
    pub name: String,
    pub tab: String,
    pub source_kind: String,
    pub access_mode: String,
    pub reason: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DraftPlan {
    pub ask: String,
    pub create: bool,
    pub name: String,
    pub inst_base: String,
    pub channel: String,
    pub web_search: bool,
    pub active: bool,
    pub updating: bool,
    pub sheets: Vec<PlannedSheet>,
    pub pending_urls: Vec<String>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum AccessPlan {
    ReadOnly,
    ReadWrite,
    Split,
}

pub fn plan_bot_draft(input: &BotDraftInput) -> DraftPlan {
    let purpose = input.purpose.trim().to_string();
    let channel = channel_from_text(&format!("{} {}", purpose, input.channel));
    let pending_urls: Vec<String> = input.sheets.iter().map(|s| s.url.clone()).filter(|u| !u.trim().is_empty()).collect();
    if !purpose_clear(&purpose) && input.bot_iid <= 0 {
        return DraftPlan {
            ask: "purpose".into(),
            create: false,
            name: String::new(),
            inst_base: String::new(),
            channel,
            web_search: false,
            active: false,
            updating: false,
            sheets: vec![],
            pending_urls,
        };
    }
    let clear = purpose_clear(&purpose);
    let name = {
        let given = input.name.trim();
        if !given.is_empty() {
            clip(given, 80)
        } else if clear {
            bot_name_from_purpose(&purpose)
        } else {
            String::new()
        }
    };
    let access = if clear { access_plan(&purpose) } else { AccessPlan::ReadOnly };
    let inst_base = {
        let given = input.inst_base.trim();
        if !given.is_empty() {
            given.to_string()
        } else if clear {
            inst_base_build(&name, &purpose, access, input.web_search)
        } else {
            String::new()
        }
    };
    let (sheets, ask_split) = plan_sheets(&purpose, access, &input.sheets);
    let sheet_missing = sheets.is_empty() && clear && wants_sheet(&purpose);
    let ask = if ask_split {
        "split".into()
    } else if sheet_missing {
        "sheet_url".into()
    } else {
        String::new()
    };
    DraftPlan {
        ask,
        create: true,
        name,
        inst_base,
        channel,
        web_search: input.web_search,
        active: input.activate,
        updating: input.bot_iid > 0,
        sheets,
        pending_urls,
    }
}

pub fn draft_summary(plan: &DraftPlan, locale: &str, attached: &[PlannedSheet]) -> String {
    let id = locale_id(locale);
    if plan.ask == "purpose" {
        return if id { "Bot-nya untuk apa?".into() } else { "What should this bot do?".into() };
    }
    let sheets = if attached.is_empty() { plan.sheets.as_slice() } else { attached };
    let mut lines = Vec::new();
    let state = if plan.active {
        if id { "sudah aktif" } else { "on" }
    } else if id {
        "masih mati"
    } else {
        "still off"
    };
    let headline = if plan.updating && !plan.active {
        format!("Bot {}.", plan.name)
    } else if id {
        let verb = if plan.updating { "diperbarui" } else { "dibuat" };
        format!("Bot {} {verb}, {state}.", plan.name)
    } else {
        let verb = if plan.updating { "updated" } else { "drafted" };
        format!("Bot {} is {verb}, {state}.", plan.name)
    };
    lines.push(headline);
    lines.push(String::new());
    let brief = purpose_brief(&plan.inst_base);
    if !brief.is_empty() {
        lines.push(if id { format!("Instruksi: {brief}") } else { format!("Instruction: {brief}") });
        lines.push(String::new());
    }
    for s in sheets {
        let mode = mode_label(&s.access_mode, id);
        lines.push(format!("- {} — {mode} ({})", s.name, s.reason));
    }
    if plan.ask == "split" {
        lines.push(String::new());
        lines.push(if id {
            "Itu dua sheet, atau satu sheet dengan dua tab? Yang dibaca saja, dan yang dicatat atau ditandai.".into()
        } else {
            "Is that two sheets, or one sheet with two tabs? One is read only, the other records or updates.".into()
        });
        return lines.join("\n");
    }
    if plan.ask == "sheet_url" {
        lines.push(if id { "Kirim link sheet-nya.".into() } else { "Send the sheet link.".into() });
    }
    if !plan.channel.is_empty() && plan.ask != "sheet_url" {
        let ch = channel_label(&plan.channel, id);
        lines.push(if id {
            format!("{ch} disambungkan dari halaman Bots. Aktifkan sekarang, atau sambungkan dulu?")
        } else {
            format!("Connect {ch} from the Bots page. Turn it on now, or connect first?")
        });
    } else if plan.ask.is_empty() && !plan.active {
        lines.push(if id { "Aktifkan?".into() } else { "Turn it on?".into() });
    }
    lines.join("\n")
}

pub fn locale_id(locale: &str) -> bool {
    let l = locale.trim().to_ascii_lowercase();
    l.is_empty() || l.starts_with("id")
}

fn purpose_brief(inst_base: &str) -> String {
    inst_base.lines().nth(1).unwrap_or("").trim().to_string()
}

pub fn bot_name_from_purpose(purpose: &str) -> String {
    let lower = purpose.trim().to_lowercase();
    let mut rest = lower.as_str();
    for p in ["buat bot ", "bikin bot ", "create a bot ", "create bot ", "new bot ", "bot baru ", "bot untuk ", "bot "] {
        if let Some(stripped) = rest.strip_prefix(p) {
            rest = stripped;
            break;
        }
    }
    let stop = rest.find(['.', '!', '?']).unwrap_or(rest.len());
    let skip = ["jawab", "answer", "untuk", "yang", "bisa", "agar", "supaya", "to", "that", "can"];
    let words: Vec<String> = rest[..stop]
        .split_whitespace()
        .filter(|w| !w.contains("http") && !w.contains("docs.google"))
        .skip_while(|w| skip.contains(w))
        .take(3)
        .map(|w| title_word(w))
        .collect();
    if words.is_empty() { "Bot".into() } else { words.join(" ") }
}

fn title_word(w: &str) -> String {
    let mut c = w.chars();
    match c.next() {
        None => String::new(),
        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
    }
}

pub fn purpose_clear(purpose: &str) -> bool {
    let filler = [
        "buat", "bikin", "create", "bot", "untuk", "yang", "pakai", "gunakan", "dengan", "ini", "itu", "sheet",
        "spreadsheet", "google", "drive", "link", "url", "the", "a", "an", "for", "using", "this", "my", "new",
        "baru", "tolong", "please", "saya", "aku", "from", "and", "dan",
    ];
    purpose.split_whitespace().any(|raw| {
        let w = raw.trim_matches(|c: char| !c.is_alphanumeric()).to_ascii_lowercase();
        w.len() >= 3 && !w.contains("http") && !w.contains("docs") && !filler.contains(&w.as_str())
    })
}

fn wants_sheet(purpose: &str) -> bool {
    let words = [
        "sheet", "spreadsheet", "menu", "stok", "stock", "katalog", "catalog", "jadwal", "schedule", "faq", "sop",
        "reservasi", "reservation", "antrian", "queue", "keluhan", "order",
    ];
    let text = format!(" {} ", norm(purpose));
    words.iter().any(|w| text.contains(&format!(" {w} ")))
}

fn channel_from_text(text: &str) -> String {
    let t = norm(text);
    if t.split_whitespace().any(|w| w == "whatsapp" || w == "wa") {
        "whatsapp".into()
    } else if t.split_whitespace().any(|w| w == "telegram" || w == "tg") {
        "telegram".into()
    } else {
        String::new()
    }
}

fn channel_label(channel: &str, id: bool) -> &'static str {
    match (channel, id) {
        ("telegram", true) => "Telegram",
        ("telegram", false) => "Telegram",
        (_, true) => "WhatsApp",
        _ => "WhatsApp",
    }
}

fn access_plan(text: &str) -> AccessPlan {
    match (write_signal(text), read_signal(text)) {
        (true, true) => AccessPlan::Split,
        (true, false) => AccessPlan::ReadWrite,
        _ => AccessPlan::ReadOnly,
    }
}

fn write_signal(text: &str) -> bool {
    let t = format!(" {} ", norm(text));
    const PHRASES: &[&str] = &[
        "kurangi stok", "kurangi stock", "reduce stock", "mark reserved", "tandai", "booking", "booked",
        "reservasi", "reservation", "reserve", "catat", "antrian", "waitlist", "keluhan", "complaint",
        "daftar hadir", "absen", "ubah status", "update status", "catat order", "order masuk",
    ];
    PHRASES.iter().any(|p| t.contains(&format!(" {p} ")) || (p.contains(' ') && t.contains(p)))
}

fn read_signal(text: &str) -> bool {
    let t = format!(" {} ", norm(text));
    const WORDS: &[&str] = &[
        "jawab", "answer", "faq", "kebijakan", "policy", "sop", "menu", "harga", "price", "jadwal", "schedule",
        "katalog", "catalog", "spesifikasi", "stok", "stock",
    ];
    WORDS.iter().any(|w| t.contains(&format!(" {w} ")))
}

fn norm(text: &str) -> String {
    text.to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { ' ' })
        .collect::<String>()
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

fn plan_sheets(purpose: &str, access: AccessPlan, sheets: &[SheetIn]) -> (Vec<PlannedSheet>, bool) {
    let mut drafted: Vec<Option<PlannedSheet>> = sheets
        .iter()
        .filter(|s| !s.url.trim().is_empty())
        .map(|s| draft_one(purpose, s))
        .collect();
    match access {
        AccessPlan::ReadOnly | AccessPlan::ReadWrite => {
            let mode = if access == AccessPlan::ReadWrite { "read_write" } else { "read_only" };
            for slot in drafted.iter_mut().flatten() {
                if slot.source_kind == "google_sheet" && slot.access_mode.is_empty() {
                    slot.access_mode = mode.into();
                    slot.reason = reason_for(mode, purpose, &slot.name);
                }
            }
        }
        AccessPlan::Split => fill_split(purpose, &mut drafted),
    }
    let ask_split = access == AccessPlan::Split && drafted.iter().any(|s| s.is_none() || s.as_ref().is_some_and(|p| p.access_mode.is_empty()));
    let ready = drafted.into_iter().flatten().filter(|s| !s.access_mode.is_empty() && !s.source_kind.is_empty()).collect();
    (ready, ask_split)
}

fn draft_one(purpose: &str, sheet: &SheetIn) -> Option<PlannedSheet> {
    let url = sheet.url.trim().to_string();
    let kind = source_kind_from_url(&url)?;
    let tab = sheet.tab.trim().to_string();
    let name = sheet_name(sheet, kind, &tab);
    if kind != "google_sheet" {
        return Some(PlannedSheet {
            url,
            name,
            tab,
            source_kind: kind.into(),
            access_mode: "read_only".into(),
            reason: reason_doc(),
        });
    }
    let explicit = mode_norm(&sheet.access_mode);
    let from_label = label_mode(&format!("{} {}", sheet.name, sheet.tab));
    let (access_mode, reason) = match explicit.or(from_label) {
        Some(mode) => (mode.to_string(), reason_for(mode, purpose, &name)),
        None => (String::new(), String::new()),
    };
    Some(PlannedSheet { url, name, tab, source_kind: kind.into(), access_mode, reason })
}

fn fill_split(purpose: &str, drafted: &mut [Option<PlannedSheet>]) {
    let known_ro = drafted.iter().flatten().any(|s| s.access_mode == "read_only");
    let known_rw = drafted.iter().flatten().any(|s| s.access_mode == "read_write");
    let unknown: Vec<usize> = drafted
        .iter()
        .enumerate()
        .filter_map(|(i, s)| s.as_ref().filter(|p| p.source_kind == "google_sheet" && p.access_mode.is_empty()).map(|_| i))
        .collect();
    let mode = match (unknown.len(), known_ro, known_rw) {
        (1, true, false) => Some("read_write"),
        (1, false, true) => Some("read_only"),
        _ => None,
    };
    if let Some(mode) = mode {
        if let Some(i) = unknown.first() {
            if let Some(slot) = drafted.get_mut(*i).and_then(|s| s.as_mut()) {
                slot.access_mode = mode.into();
                slot.reason = reason_for(mode, purpose, &slot.name);
            }
        }
    }
    for slot in drafted.iter_mut() {
        if slot.as_ref().is_some_and(|s| s.access_mode.is_empty()) {
            *slot = None;
        }
    }
}

fn label_mode(label: &str) -> Option<&'static str> {
    match (write_signal(label), read_signal(label)) {
        (true, false) => Some("read_write"),
        (false, true) => Some("read_only"),
        _ => None,
    }
}

fn sheet_name(sheet: &SheetIn, kind: &str, tab: &str) -> String {
    let base = sheet.name.trim();
    let base = if base.is_empty() {
        if !tab.is_empty() { tab } else { kind_fallback(kind) }
    } else if !tab.is_empty() && !base.to_lowercase().contains(&tab.to_lowercase()) {
        return clip(&format!("{base} / {tab}"), 120);
    } else {
        base
    };
    clip(base, 120)
}

fn kind_fallback(kind: &str) -> &'static str {
    match kind {
        "google_doc" => "Dokumen",
        "google_slide" => "Slide",
        _ => "Sheet",
    }
}

pub fn source_kind_from_url(url: &str) -> Option<&'static str> {
    let u = url.to_ascii_lowercase();
    if u.contains("/spreadsheets/") {
        Some("google_sheet")
    } else if u.contains("/document/") {
        Some("google_doc")
    } else if u.contains("/presentation/") {
        Some("google_slide")
    } else {
        None
    }
}

fn mode_norm(raw: &str) -> Option<&'static str> {
    match raw.trim().to_ascii_lowercase().as_str() {
        "read_only" | "read" | "readonly" | "ro" => Some("read_only"),
        "read_write" | "write" | "readwrite" | "rw" => Some("read_write"),
        _ => None,
    }
}

fn mode_label(mode: &str, id: bool) -> &'static str {
    match (mode == "read_write", id) {
        (true, true) => "baca-tulis",
        (true, false) => "read write",
        (false, true) => "baca saja",
        (false, false) => "read only",
    }
}

fn reason_for(mode: &str, purpose: &str, label: &str) -> String {
    let text = format!("{purpose} {label}");
    if mode == "read_write" { reason_write(&text) } else { reason_read(&text) }
}

fn reason_write(text: &str) -> String {
    let t = norm(text);
    if t.contains("reserv") || t.contains("booking") || t.contains("booked") || t.contains("tandai") {
        "tandai booking".into()
    } else if t.contains("kurangi") || t.contains("reduce stock") {
        "kurangi stok".into()
    } else if t.contains("antrian") || t.contains("waitlist") || t.contains("queue") {
        "catat antrian".into()
    } else if t.contains("keluhan") || t.contains("complaint") {
        "catat keluhan".into()
    } else {
        "catat atau tandai".into()
    }
}

fn reason_read(text: &str) -> String {
    let t = norm(text);
    if t.contains("stok") || t.contains("stock") {
        "jawab stok".into()
    } else if t.contains("menu") {
        "jawab menu".into()
    } else if t.contains("harga") || t.contains("price") {
        "jawab harga".into()
    } else if t.contains("jadwal") || t.contains("schedule") {
        "jawab jadwal".into()
    } else {
        "jawab dari sheet".into()
    }
}

fn reason_doc() -> String {
    "dokumen hanya dibaca".into()
}

fn inst_base_build(name: &str, purpose: &str, access: AccessPlan, web_search: bool) -> String {
    let rule = match access {
        AccessPlan::ReadOnly => "Jangan mengubah isi sheet.",
        AccessPlan::ReadWrite => "Kamu boleh menambah atau mengubah baris hanya untuk tugas di atas.",
        AccessPlan::Split => "Sheet baca saja hanya untuk menjawab. Sheet baca-tulis hanya untuk mencatat atau menandai.",
    };
    let web = if web_search { " Kamu boleh mencari web untuk informasi di luar sheet." } else { "" };
    format!("Kamu adalah {name}.\n{purpose}\nGunakan sheet yang terpasang sebagai sumber. {rule}{web}\nJika data tidak ada, katakan tidak tahu.")
}

fn clip(s: &str, max: usize) -> String {
    s.chars().take(max).collect()
}

pub fn sheet_config(sheet: &PlannedSheet) -> Value {
    let mut config = json!({
        "view_url": sheet.url,
        "access_mode": sheet.access_mode,
    });
    if !sheet.tab.is_empty() {
        config["sheet_name"] = json!(sheet.tab);
    }
    config
}

pub fn flag_true(raw: &str) -> bool {
    matches!(raw.trim().to_ascii_lowercase().as_str(), "1" | "true" | "yes" | "ya" | "on")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn input(purpose: &str, sheets: Vec<SheetIn>) -> BotDraftInput {
        BotDraftInput {
            purpose: purpose.into(),
            name: String::new(),
            inst_base: String::new(),
            bot_iid: 0,
            channel: String::new(),
            activate: false,
            web_search: false,
            sheets,
        }
    }

    fn sheet(url: &str, name: &str) -> SheetIn {
        SheetIn { url: url.into(), name: name.into(), tab: String::new(), access_mode: String::new() }
    }

    #[test]
    fn purpose_missing_does_not_create() {
        let plan = plan_bot_draft(&input("buat bot yang pakai sheet ini", vec![sheet("https://docs.google.com/spreadsheets/d/aaa/edit", "")]));
        assert!(!plan.create);
        assert_eq!(plan.ask, "purpose");
        assert_eq!(plan.pending_urls.len(), 1);
        assert_eq!(draft_summary(&plan, "id-ID", &[]), "Bot-nya untuk apa?");
    }

    #[test]
    fn stock_is_read_only_and_named() {
        let plan = plan_bot_draft(&input(
            "Bot untuk jawab stok barang",
            vec![sheet("https://docs.google.com/spreadsheets/d/ccc/edit", "Stok")],
        ));
        assert!(plan.create);
        assert!(!plan.active);
        assert_eq!(plan.name, "Stok Barang");
        assert_eq!(plan.sheets.len(), 1);
        assert_eq!(plan.sheets[0].access_mode, "read_only");
        assert_eq!(plan.sheets[0].reason, "jawab stok");
        assert!(plan.inst_base.contains("Jangan mengubah isi sheet"));
    }

    #[test]
    fn reservation_write_and_whatsapp() {
        let plan = plan_bot_draft(&input("Buat bot reservasi resto, tandai meja, nanti dipakai di WhatsApp", vec![]));
        assert!(plan.create);
        assert_eq!(plan.channel, "whatsapp");
        assert_eq!(plan.ask, "sheet_url");
        assert!(plan.inst_base.contains("menambah atau mengubah"));
        let summary = draft_summary(&plan, "id-ID", &[]);
        assert!(summary.contains("masih mati"));
        assert!(summary.contains("Kirim link sheet-nya"));
    }

    #[test]
    fn menu_and_booking_split_without_one_sheet() {
        let plan = plan_bot_draft(&input(
            "Buat bot reservasi. Jawab menu dari sheet, dan tandai meja yang sudah di-booking.",
            vec![sheet("https://docs.google.com/spreadsheets/d/aaa/edit", "")],
        ));
        assert!(plan.create);
        assert_eq!(plan.ask, "split");
        assert!(plan.sheets.is_empty());
    }

    #[test]
    fn split_uses_tab_names() {
        let mut stok = sheet("https://docs.google.com/spreadsheets/d/eee/edit#gid=0", "Stok");
        stok.tab = "Stok".into();
        let mut order = sheet("https://docs.google.com/spreadsheets/d/eee/edit#gid=1", "Order");
        order.tab = "Order".into();
        order.name = "Order".into();
        let plan = plan_bot_draft(&input("Bot yang bisa jawab stok dan sekaligus kurangi stok kalau ada order", vec![stok, order]));
        assert_eq!(plan.ask, "");
        assert_eq!(plan.sheets[0].access_mode, "read_only");
        assert_eq!(plan.sheets[1].access_mode, "read_write");
    }

    #[test]
    fn doc_is_read_only() {
        let plan = plan_bot_draft(&input(
            "Jawab FAQ dari dokumen",
            vec![sheet("https://docs.google.com/document/d/zzz/edit", "FAQ")],
        ));
        assert_eq!(plan.sheets[0].source_kind, "google_doc");
        assert_eq!(plan.sheets[0].access_mode, "read_only");
    }

    #[test]
    fn front_desk_does_not_ask_for_a_sheet() {
        let plan = plan_bot_draft(&input("Sapa pelanggan dan sebutkan alamat toko", vec![]));
        assert!(plan.create);
        assert_eq!(plan.ask, "");
        assert!(plan.sheets.is_empty());
    }
}
