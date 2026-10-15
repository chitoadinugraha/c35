//! Google Sheets in Chrome on @device Windows/desktop (not browser.sheets API).

use serde_json::Value;

pub const GOOGLE_SHEETS_DESKTOP_PLAYBOOK: &str = "[GOOGLE SHEETS ON DEVICE] \
Turn 0 already provides a Set-of-Mark desktop observation with Canvas OCR. For subsequent steps or verification, call device.screenshot with som=true. \
Use direct stepwise device.input (with ctrl+g goto name box and type_text) — never tell the user to type in cells or rename the title themselves. \
Desktop @device uses OS device.input only — never browser.sheets.* (extension API) and never shell.run PowerShell/SendKeys/WScript for spreadsheet typing or sample rows. \
Always use device.input (with batch actions: [...] or click_and_type). \
Launch: shell.run may open Chrome or https://sheets.new only when no Sheets tab is visible; reuse an existing spreadsheet tab when present. \
Before entering headers or data: dismiss every blocker on screen — onboarding modals (Got it, No thanks), side panels (Tables — X), top promo banners (X), sign-in nags. \
Canvas text discovery: utilize [CanvasText] tags from Set-of-Mark observation to locate existing columns, headers, and sheet tabs across the canvas grid. \
Combine canvas text discovery with Ctrl+G (Go to range) for precise cell addressing — never guess pixel coordinates on the grid. \
Row-1 headers: goto A1, B1, C1 (ctrl+g each + enter or type_text + tab) in a single batched device.input actions: [...] — never guess pixel coordinates on the grid. Verify the row once headers are entered, not after each individual keystroke. \
Sample data rows: batch consecutive cell entries into device.input actions: [...] (e.g. [shortcut ctrl+g, type_text A2, shortcut enter, type_text Budi, shortcut tab, type_text Jakarta, shortcut tab, type_text Laki-laki, shortcut enter, type_text Siti, shortcut tab, ...]). Avoid taking unnecessary screenshots between every cell; batch related rows together before verifying formula bar or [CanvasText] tags. \
Spreadsheet title: click the Rename control (Untitled spreadsheet) and click_and_type the new title — not manual directions to the user. \
If text lands in the wrong column (e.g. GenderNama, or D1/E1 filled for a 3-column task), clear and redo. \
Finish only when the screenshot proves the requested title, headers, and row count — not when a shell script was attempted.";

/// On @device Windows/desktop, execute directly via device.input using name box or shortcuts.
pub const GOOGLE_SHEETS_PARENT_TURN_RULE: &str = "[GOOGLE SHEETS DIRECT INPUT] \
Execute cell edits, clicks, and text typing directly using device.input with batch actions [shortcut ctrl+g, type_text C3, shortcut enter]. \
Do not delegate to background subagents for single-turn cell edits, clicks, or simple typing.";

pub const GOOGLE_SHEETS_PARENT_CONTINUE_HINT: &str = "Google Sheets on @device is not done yet. \
Continue using device.input with the name box (A1, B1, A2…) and verify with device.screenshot (som=true) — not pixel guesses. \
Do not tell the user the sheet is finished until a screenshot shows the requested rows/title.";

pub const GOOGLE_SHEETS_BOLD_CONTINUE_HINT: &str = "Google Sheets header bolding is NOT verified yet. \
CRITICAL VERIFICATION: \
1. Look at the toolbar Bold 'B' button (x=0.665, y=0.251). It MUST have an active blue container background. If the 'B' button is grey/white, bold is OFF! \
2. In Google Sheets, if cells previously had mixed formatting, clicking 'B' once toggles bold OFF. You MUST click 'B' at (x=0.665, y=0.251) again or press shortcut ctrl+b until the 'B' button turns active blue and all header cells (Nama, Alamat, Jenis Kelamin) become bold. \
Do not conclude until the 'B' button is visibly active blue.";

pub const GOOGLE_SHEETS_ROW_INSERT_CONTINUE_HINT: &str = "Google Sheets data row insertion is NOT verified yet! \
CRITICAL: You have not typed the new data rows into the sheet yet. \
To insert the requested rows: \
1. If the Themes sidebar is open on the right, close it first (click Close X at x=0.956, y=0.266). \
2. Use Name Box or ctrl+g to navigate to the first empty row (e.g. cell A4 or A5). \
3. Type the data values using device.input: type_text for first cell, shortcut 'tab' to next column, type_text for second cell, shortcut 'tab', type_text for third cell, shortcut 'enter' for next row. \
4. DO NOT click random toolbar buttons. Type the actual row data requested by the user. \
Do not claim success until the new rows are visibly typed into the sheet.";

pub fn google_sheets_continue_hint(goal: &str) -> &'static str {
    if goal_requires_bold(goal) {
        GOOGLE_SHEETS_BOLD_CONTINUE_HINT
    } else if looks_like_sheet_row_insert_intent(&goal.to_ascii_lowercase()) {
        GOOGLE_SHEETS_ROW_INSERT_CONTINUE_HINT
    } else {
        GOOGLE_SHEETS_PARENT_CONTINUE_HINT
    }
}
/// Exact device.input pattern for selecting a cell without grid pixel clicks (Google Sheets web).
pub const GOOGLE_SHEETS_GOTO_RECIPE: &str = "[GOOGLE SHEETS GOTO CELL] \
Never shell.run SendKeys/WScript.AppActivate for typing. Never click_and_type on the grid until the name box shows the target (e.g. A2). \
To select a cell: device.input actions [shortcut ctrl+g, type_text A2, shortcut enter] (Go to range). Confirm in screenshot that the name box reads A2 (not E5/E8). \
Batch entries together into actions: [...]: e.g. for Row 2 + Row 3: [shortcut ctrl+g, type_text A2, shortcut enter, type_text Budi, shortcut tab, type_text Jakarta, shortcut tab, type_text Laki-laki, shortcut enter, shortcut ctrl+g, type_text A3, shortcut enter, type_text Siti, shortcut tab, type_text Surabaya, shortcut tab, type_text Perempuan]. Batching avoids roundtrips and optimizes context usage. \
Use Tab only after the correct cell is selected — wrong column means clear and goto again. \
If data appears under column E or below row 4 while filling sample rows, undo and redo with goto A2.";


pub use crate::prompt::google_forms::ComputerUseToolCounts;
use crate::prompt::computer_use::computer_use_final_text_acceptable;

const HEADER_TOKENS: &[&str] = &[
    "name",
    "address",
    "gender",
    "nama",
    "alamat",
    "jenis kelamin",
];

fn header_token_hits(t: &str) -> u32 {
    HEADER_TOKENS.iter().filter(|tok| t.contains(*tok)).count() as u32
}

fn device_mention_in_text(text: &str) -> bool {
    text.contains("[@iid:") || text.contains("@iid:")
}

fn text_mentions_google_sheet(t: &str) -> bool {
    t.contains("google sheet")
        || t.contains("google sheets")
        || t.contains("spreadsheet")
        || t.contains("sheets.new")
        || t.contains("lembar kerja")
        || t.contains("that sheet")
        || t.contains("the sheet")
        || t.contains("lembar")
}

/// Add/insert rows on an open sheet (English/ID), with or without "google sheet" in the phrase.
fn looks_like_sheet_row_insert_intent(t: &str) -> bool {
    let row = t.contains("row") || t.contains("rows") || t.contains("baris");
    if !row {
        return false;
    }
    t.contains("add")
        || t.contains("more")
        || t.contains("insert")
        || t.contains("append")
        || t.contains("tambah")
        || t.contains("tambahkan")
        || t.contains("new row")
        || t.contains("another row")
}

/// @device follow-ups while Chrome Sheets is already the task (no "google sheet" required).
fn looks_like_sheet_scoped_followup(t: &str) -> bool {
    if t.contains("change that")
        || t.contains("change it")
        || t.contains("update that")
        || t.contains("add it")
        || t.contains("what is on")
        || t.contains("what's on")
        || t.contains("bold")
        || t.contains("tebal")
        || t.contains("header")
        || looks_like_sheet_row_insert_intent(t)
    {
        return true;
    }
    let ui_keys = t.contains("mouse click")
        || t.contains("send key")
        || t.contains("send keys")
        || t.contains("keyboard");
    ui_keys && (text_mentions_google_sheet(t) || t.contains("add it"))
}

fn looks_like_device_sheet_scoped_ui(text: &str) -> bool {
    if !device_mention_in_text(text) {
        return false;
    }
    let t = text.to_ascii_lowercase();
    if text_mentions_google_sheet(&t) {
        return true;
    }
    if looks_like_sheet_scoped_followup(&t) {
        return true;
    }
    if spreadsheet_cell_ref_in_text(text)
        && (t.contains("on ")
            || t.contains("what")
            || t.contains("see")
            || t.contains("change")
            || t.contains("cell"))
    {
        return true;
    }
    false
}

fn looks_like_sheet_create_intent(t: &str) -> bool {
    if !text_mentions_google_sheet(t) {
        return false;
    }
    t.contains("open")
        || t.contains("create")
        || t.contains("new")
        || t.contains("field")
        || t.contains("header")
        || t.contains("column")
        || t.contains("isi")
        || t.contains("buat")
        || t.contains("buka")
        || header_token_hits(t) >= 1
}

fn looks_like_sheet_cell_edit_intent(t: &str) -> bool {
    let edit = t.contains("ubah")
        || t.contains("rename")
        || t.contains("ganti")
        || t.contains("edit ")
        || t.contains("edit cell")
        || t.contains("isi ")
        || t.contains("ketik")
        || t.contains("bahasa indonesia")
        || t.contains("=>")
        || t.contains("->")
        || t.contains(" jadi ");
    if !edit {
        return false;
    }
    header_token_hits(t) >= 2
}

/// Rows, title, or other in-Chrome edits while a sheet is already open on @device.
fn looks_like_sheet_device_ui_intent(t: &str) -> bool {
    if !text_mentions_google_sheet(t) {
        return false;
    }
    t.contains("tambah")
        || t.contains("tambahkan")
        || t.contains("baris")
        || t.contains("contoh")
        || t.contains("sample row")
        || t.contains("judul")
        || t.contains("title")
        || t.contains("append row")
        || t.contains("isi data")
        || t.contains("isi baris")
        || t.contains("data sample")
        || t.contains("sample data")
        || t.contains("data contoh")
}


fn token_has_spreadsheet_cell_ref(token: &str) -> bool {
    let w = token
        .trim_matches(|c: char| !c.is_ascii_alphanumeric())
        .to_ascii_lowercase();
    if w.len() < 2 || w.len() > 5 {
        return false;
    }
    let mut it = w.chars();
    let col = it.next().unwrap_or(' ');
    if !col.is_ascii_alphabetic() {
        return false;
    }
    let rest = it.as_str();
    !rest.is_empty() && rest.chars().all(|c| c.is_ascii_digit())
}

pub fn spreadsheet_cell_ref_in_text(text: &str) -> bool {
    text.split_whitespace().any(token_has_spreadsheet_cell_ref)
}

/// @device phrases like `ubah A2 to "X"` without saying "google sheet".
pub fn user_text_looks_like_spreadsheet_cell_ref_edit(text: &str) -> bool {
    if !spreadsheet_cell_ref_in_text(text) {
        return false;
    }
    let t = text.to_ascii_lowercase();
    t.contains("ubah")
        || t.contains("ganti")
        || t.contains("edit")
        || t.contains("change")
        || t.contains(" to ")
        || t.contains(" jadi ")
        || t.contains("isi ")
        || t.contains("set ")
        || t.contains("ketik")
}

pub fn user_text_looks_like_device_spreadsheet_ui(user: &str) -> bool {
    if user_text_looks_like_google_sheets_desktop(user) {
        return true;
    }
    if looks_like_device_sheet_scoped_ui(user) {
        return true;
    }
    let scoped = device_mention_in_text(user);
    scoped && user_text_looks_like_spreadsheet_cell_ref_edit(user)
}
/// Desktop Chrome Sheets UI on a paired @device (not extension browser.sheets.*).
pub fn user_text_looks_like_google_sheets_desktop(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    looks_like_sheet_create_intent(&t)
        || looks_like_sheet_cell_edit_intent(&t)
        || looks_like_sheet_device_ui_intent(&t)
        || looks_like_device_sheet_scoped_ui(text)
}

fn push_unique_header(out: &mut Vec<String>, s: &str) {
    if s.is_empty() || out.iter().any(|x| x.eq_ignore_ascii_case(s)) {
        return;
    }
    out.push(s.to_string());
}

pub fn google_sheets_target_headers_in_goal(goal: &str) -> Vec<String> {
    let g = goal.to_ascii_lowercase();
    let mut out: Vec<String> = Vec::new();
    if g.contains("nama") || g.contains("name => nama") || g.contains("name jadi nama") {
        push_unique_header(&mut out, "nama");
    }
    if g.contains("alamat") || g.contains("address jadi alamat") || g.contains("address => alamat") {
        push_unique_header(&mut out, "alamat");
    }
    if g.contains("jenis kelamin")
        || g.contains("gender jadi jenis")
        || g.contains("gender => jenis")
    {
        push_unique_header(&mut out, "jenis kelamin");
    }
    if out.is_empty() && google_sheets_header_build(goal) {
        if g.contains("name") {
            push_unique_header(&mut out, "name");
        }
        if g.contains("address") {
            push_unique_header(&mut out, "address");
        }
        if g.contains("gender") {
            push_unique_header(&mut out, "gender");
        }
    }
    out
}

fn header_tokens_in_goal(goal: &str) -> Vec<&'static str> {
    let g = goal.to_ascii_lowercase();
    HEADER_TOKENS
        .iter()
        .copied()
        .filter(|t| g.contains(t))
        .collect()
}

pub fn google_sheets_header_build(goal: &str) -> bool {
    header_token_hits(&goal.to_ascii_lowercase()) >= 2
        || goal.to_ascii_lowercase().contains("field")
        || goal.to_ascii_lowercase().contains("header")
        || goal.to_ascii_lowercase().contains("column")
        || goal.to_ascii_lowercase().contains("baris 1")
        || goal.to_ascii_lowercase().contains("baris contoh")
}

fn digits_immediately_before(g: &str, keyword: &str) -> Option<u32> {
    let pos = g.find(keyword)?;
    let before = g[..pos].trim();
    let mut digits = String::new();
    for ch in before.chars().rev() {
        if ch.is_ascii_digit() {
            digits.push(ch);
        } else if !digits.is_empty() {
            break;
        }
    }
    if digits.is_empty() {
        return None;
    }
    let n: u32 = digits.chars().rev().collect::<String>().parse().unwrap_or(0);
    if n == 0 { None } else { Some(n) }
}

/// How many sample rows the user asked for (e.g. "3 data sample", "5 baris contoh").
pub fn google_sheets_sample_row_count(goal: &str) -> u32 {
    let g = goal.to_ascii_lowercase();
    for kw in [
        "baris contoh",
        "baris sample",
        "data sample",
        "sample data",
        "data contoh",
        "baris",
    ] {
        if let Some(n) = digits_immediately_before(&g, kw) {
            return n.min(20);
        }
    }
    if g.contains("contoh") || g.contains("sample") {
        return 3;
    }
    0
}

pub fn google_sheets_min_tool_counts(goal: &str) -> ComputerUseToolCounts {
    let g = goal.to_ascii_lowercase();
    if !google_sheets_header_build(goal)
        && !looks_like_sheet_device_ui_intent(&g)
        && !looks_like_sheet_row_insert_intent(&g)
        && !looks_like_device_sheet_scoped_ui(goal)
    {
        return ComputerUseToolCounts::default();
    }
    let cols = header_tokens_in_goal(goal).len().max(2);
    let per_cell_verify = google_sheets_target_headers_in_goal(goal).len().max(cols);
    let row_samples = google_sheets_sample_row_count(goal) as usize;
    ComputerUseToolCounts {
        device_screenshot: (2 + per_cell_verify + row_samples).min(12) as u32,
        device_input: (3 + cols * 3 + row_samples * 2).min(24) as u32,
    }
}

pub fn google_sheets_tool_activity_sufficient(goal: &str, counts: ComputerUseToolCounts) -> bool {
    let min = google_sheets_min_tool_counts(goal);
    if min.device_input == 0 && min.device_screenshot == 0 {
        return true;
    }
    counts.device_input >= min.device_input && counts.device_screenshot >= min.device_screenshot
}

/// Returns true if the goal text indicates styling/bolding headers or cells.
pub fn goal_requires_bold(goal: &str) -> bool {
    let g = goal.to_ascii_lowercase();
    g.contains("bold") || g.contains("tebal")
}

/// Checks if the Google Sheets toolbar Bold button is in an active Material You state (light blue background pill).
pub fn is_google_sheets_bold_button_active(jpeg_bytes: &[u8]) -> Option<bool> {
    let img = image::load_from_memory(jpeg_bytes).ok()?;
    let (w, h) = (img.width(), img.height());
    if w < 200 || h < 150 {
        return None;
    }
    // Normalized bounds for the Bold 'B' button in Google Sheets toolbar
    let bx1 = (w as f32 * 0.640) as u32;
    let bx2 = ((w as f32 * 0.690) as u32).min(w);
    let by1 = (h as f32 * 0.220) as u32;
    let by2 = ((h as f32 * 0.280) as u32).min(h);
    if bx1 >= bx2 || by1 >= by2 {
        return None;
    }
    let mut blue_pixels = 0usize;
    let mut total_pixels = 0usize;
    let rgb = img.to_rgb8();
    for y in by1..by2 {
        for x in bx1..bx2 {
            let pixel = rgb.get_pixel(x, y);
            let (r, g, b) = (pixel[0] as i32, pixel[1] as i32, pixel[2] as i32);
            total_pixels += 1;
            // Material You active container: (205-220, 220-235, 245-255) where b > r + 20 and b > g + 8 and b > 200
            if b > r + 20 && b > g + 8 && b > 200 {
                blue_pixels += 1;
            }
        }
    }
    if total_pixels == 0 {
        return None;
    }
    let ratio = blue_pixels as f32 / total_pixels as f32;
    Some(ratio > 0.08)
}

pub fn is_only_cell_navigation_text(text: &str) -> bool {
    let t = text.trim();
    if t.is_empty() {
        return true;
    }
    let clean = t.replace("Sheet1!", "").replace('$', "");
    let parts: Vec<&str> = clean.split(':').collect();
    parts.iter().all(|p| {
        let p = p.trim();
        (p.starts_with(|c: char| c.is_ascii_alphabetic()) && p[1..].chars().all(|c| c.is_ascii_digit()))
            || p.chars().all(|c| c.is_ascii_digit())
    })
}

pub fn device_input_has_cell_data_typing(args: &Value) -> bool {
    let check_val = |v: &Value| -> bool {
        let ev = v.get("event_type").and_then(|s| s.as_str()).unwrap_or_default();
        let is_type = matches!(ev, "type_text" | "click_and_type");
        let text = v.get("text").and_then(|s| s.as_str()).unwrap_or_default().trim();
        is_type && !text.is_empty() && !is_only_cell_navigation_text(text)
    };
    if check_val(args) {
        return true;
    }
    if let Some(actions) = args.get("actions").and_then(|v| v.as_array()) {
        for act in actions {
            if check_val(act) {
                return true;
            }
        }
    }
    false
}

pub fn goal_requires_row_insert(goal: &str) -> bool {
    looks_like_sheet_row_insert_intent(&goal.to_ascii_lowercase())
}

/// Parent Home turn may settle only when delegate succeeded or device tools + summary prove the goal.
pub fn google_sheets_parent_turn_may_finish(
    goal: &str,
    summary: &str,
    counts: ComputerUseToolCounts,
    delegate_goal_met: bool,
    bold_verified: bool,
    has_typing: bool,
) -> bool {
    if !user_text_looks_like_device_spreadsheet_ui(goal) {
        return true;
    }
    if !computer_use_final_text_acceptable(summary) {
        return false;
    }
    if !google_sheets_summary_sufficient(goal, summary) {
        return false;
    }
    if delegate_goal_met {
        return true;
    }
    let s = summary.to_ascii_lowercase();
    let summary_claims_bold = s.contains("bold") || s.contains("tebal") || s.contains("ditebalkan");
    // If the model claims headers are bolded, bold MUST be verified!
    if (goal_requires_bold(goal) || summary_claims_bold) && !bold_verified {
        return false;
    }
    // If the goal requires inserting rows of data, data typing MUST have taken place!
    if goal_requires_row_insert(goal) && !has_typing {
        return false;
    }
    if goal_requires_bold(goal) && bold_verified {
        return true;
    }
    if goal_requires_row_insert(goal) && has_typing {
        return true;
    }
    if counts.device_input >= 1 && !goal_requires_bold(goal) && !goal_requires_row_insert(goal) {
        return true;
    }
    google_sheets_tool_activity_sufficient(goal, counts) && counts.device_screenshot >= 2
}

pub fn google_sheets_playbook_block() -> &'static str {
    GOOGLE_SHEETS_DESKTOP_PLAYBOOK
}


pub const GOOGLE_SHEETS_PIXEL_GRID_STEER_HINT: &str = "That device.input batch used click_and_type on grid coordinates without Go to range. \
Use ctrl+g, type the cell (e.g. A2), enter, then type_text + tab for each value. Screenshot must show the name box on column A before you claim success.";

pub const GOOGLE_SHEETS_SHELL_FORBIDDEN_HINT: &str = "shell.run is not allowed for Google Sheets grid edits on @device (no SendKeys, echo scripts, or COM automation). \
Use device.input with ctrl+g goto (A2, A3, …) and type_text + tab; verify with device.screenshot.";

pub fn google_sheets_shell_command_forbidden(command: &str) -> bool {
    let t = command.to_ascii_lowercase();
    t.contains("sendkeys")
        || t.contains("wscript.shell")
        || t.contains("appactivate")
        || t.contains("system.windows.forms")
        || t.contains("internetexplorer.application")
        || t.contains("simulated ui")
        || t.starts_with('#')
        || t.contains("echo \"adding")
        || t.contains("echo \"add")
}

fn google_sheets_shell_launch_allowlisted(t: &str) -> bool {
    if t.contains("sendkeys") || t.contains("wscript") {
        return false;
    }
    if t.contains("sheets.new") || t.contains("docs.google.com/spreadsheets") {
        return true;
    }
    t == "chrome"
        || t.starts_with("start chrome")
        || t.starts_with("start-process chrome")
        || (t.contains("start-process") && t.contains("chrome"))
}

/// On Sheets UI turns, block shell except minimal Chrome/sheets.new launch.
pub fn google_sheets_shell_blocked_on_ui_turn(command: &str) -> bool {
    if google_sheets_shell_command_forbidden(command) {
        return true;
    }
    let t = command.trim().to_ascii_lowercase();
    if t.is_empty() {
        return true;
    }
    !google_sheets_shell_launch_allowlisted(&t)
}

fn cell_ref_looks_like_goto(text: &str) -> bool {
    let t = text.trim().to_ascii_uppercase();
    t.len() >= 2
        && t.starts_with('A')
        && t[1..].chars().all(|c| c.is_ascii_digit())
}

pub fn google_sheets_device_input_uses_pixel_grid_without_goto(args: &serde_json::Value) -> bool {
    let actions = args
        .get("actions")
        .and_then(|v| v.as_array())
        .filter(|a| !a.is_empty());
    let actions = match actions {
        Some(a) => a,
        None => {
            let et = args
                .get("event_type")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            if et != "click_and_type" || !args.get("x").is_some() {
                return false;
            }
            return true;
        }
    };
    let mut has_goto = false;
    let mut pixel_grid = 0u32;
    for act in actions {
        let et = act
            .get("event_type")
            .and_then(|v| v.as_str())
            .unwrap_or("");
        if et == "shortcut" {
            let combo = act
                .get("text")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_ascii_lowercase();
            if combo == "ctrl+g" || combo == "ctrl+home" {
                has_goto = true;
            }
        }
        if et == "type_text" {
            let text = act.get("text").and_then(|v| v.as_str()).unwrap_or("");
            if cell_ref_looks_like_goto(text) {
                has_goto = true;
            }
        }
        if et == "click_and_type" && act.get("x").is_some() {
            pixel_grid += 1;
        }
    }
    pixel_grid > 0 && !has_goto
}

fn summary_looks_like_wrong_sample_column(summary: &str) -> bool {
    let s = summary.to_ascii_lowercase();
    ((s.contains("e5") || s.contains("e6") || s.contains("e7") || s.contains("e8"))
        && !s.contains("clear")
        && !s.contains("undo"))
        || s.contains("column e")
        || s.contains("kolom e")
}
fn summary_looks_like_wrong_row1_layout(summary: &str) -> bool {
    let s = summary.to_ascii_lowercase();
    s.contains("gendernama")
        || s.contains("gender nama")
        || (s.contains("d1") && !s.contains("d1 empty") && !s.contains("d1 kosong"))
        || (s.contains("e1") && !s.contains("e1 empty"))
        || s.contains("kolom d")
        || s.contains("column d")
        || s.contains("salah sel")
        || s.contains("wrong cell")
}

fn summary_looks_like_user_handoff(summary: &str) -> bool {
    let s = summary.to_ascii_lowercase();
    s.contains("silakan klik")
        || s.contains("please click")
        || s.contains("klik teks")
        || s.contains("ketik manual")
        || s.contains("langkah manual")
        || s.contains("menyarankan langkah manual")
        || s.contains("keterbatasan")
}

pub fn google_sheets_summary_sufficient(goal: &str, summary: &str) -> bool {
    let g = goal.to_ascii_lowercase();
    let s = summary.to_ascii_lowercase();
    if s.is_empty() {
        return false;
    }
    if summary_looks_like_wrong_row1_layout(&s)
        || summary_looks_like_wrong_sample_column(&s)
        || summary_looks_like_user_handoff(&s) {
        return false;
    }
    if s.contains("anda bisa mengetik")
        || s.contains("you can type")
        || s.contains("type directly")
        || s.contains("if automation")
        || s.contains("jika input otomatis")
        || s.contains("tidak memiliki akses")
        || s.contains("tidak memiliki kemampuan")
        || s.contains("do not have device.input")
        || s.contains("not in the `declaration` list")
        || s.contains("sendkeys")
    {
        return false;
    }
    if g.contains("judul") || g.contains("title") {
        if s.contains("untitled spreadsheet") && !s.contains("renamed") && !s.contains("diubah") {
            return false;
        }
    }
    let opening_only = [
        "opened chrome",
        "opened google chrome",
        "membuka chrome",
        "sheets.new",
        "spreadsheet baru",
        "new spreadsheet",
        "terbuka di browser",
    ];
    let claims_done = [
        "filled",
        "entered",
        "header",
        "kolom",
        "column",
        "selesai",
        "finished",
        "completed",
        "berhasil",
        "verified",
        "diverifikasi",
        "a1",
        "b1",
        "c1",
        "test anggota",
    ];
    if opening_only.iter().any(|k| s.contains(k)) && !claims_done.iter().any(|k| s.contains(k)) {
        return false;
    }
    let targets = google_sheets_target_headers_in_goal(goal);
    if targets.len() >= 2 {
        let matched = targets.iter().filter(|t| s.contains(t.as_str())).count();
        if matched < targets.len() {
            return false;
        }
    }
    if google_sheets_sample_row_count(goal) > 0
        || g.contains("contoh")
        || g.contains("sample")
        || g.contains("data sample")
    {
        let has_proof = s.contains("baris")
            || s.contains("row")
            || s.contains("a2")
            || s.contains("screenshot")
            || s.contains("terverifikasi")
            || s.contains("verified")
            || s.contains("terlihat")
            || s.contains("diverifikasi");
        if s.contains("berhasil") && !has_proof {
            return false;
        }
    }
    if google_sheets_header_build(goal) || looks_like_sheet_device_ui_intent(&g) {
        return claims_done.iter().any(|k| s.contains(k)) || targets.len() >= 2;
    }
    if g.contains("open") || g.contains("buka") {
        return claims_done.iter().any(|k| s.contains(k)) || s.contains("sheet");
    }
    true
}

#[cfg(test)]
mod tests {
    use serde_json::json;
    use super::*;

    #[test]
    fn desktop_sheets_sample_rows_and_title() {
        let t = "[@iid:1]tambahkan 5 baris contoh, ubah judul google sheet jadi Test Anggota";
        assert!(user_text_looks_like_google_sheets_desktop(t));
    }

    #[test]
    fn desktop_sheets_rename_headers_without_sheet_keyword() {
        let t = "[@iid:98063412749627392]ubah jadi bahasa indonesia, name => nama, rename address jadi alamat, gender jadi jenis kelamin";
        assert!(user_text_looks_like_google_sheets_desktop(t));
    }

    #[test]
    fn summary_rejects_manual_title_handoff() {
        let goal = "ubah judul google sheet jadi Test Anggota, tambah 5 baris";
        assert!(!google_sheets_summary_sufficient(
            goal,
            "Data sudah saya masukkan. Silakan klik Untitled spreadsheet dan ketik Test Anggota."
        ));
    }

    #[test]
    fn sample_row_count_parses_indonesian() {
        assert_eq!(
            google_sheets_sample_row_count(
                "di google sheet yang terbuka, bisakah kamu menambahkan 3 data sample?"
            ),
            3
        );
        assert_eq!(google_sheets_sample_row_count("tambahkan 5 baris contoh"), 5);
    }

    #[test]
    fn summary_rejects_berhasil_without_proof() {
        let goal = "google sheet terbuka tambahkan 3 data sample";
        assert!(!google_sheets_summary_sufficient(
            goal,
            "Data sampel telah berhasil ditambahkan ke Google Sheet Anda."
        ));
    }

    #[test]
    fn vm_chat_add_rows_and_change_that_match_scoped_sheets() {
        let add = "[@iid:98063412749627392|VM1]now can you add 2 more row to that sheet?";
        assert!(user_text_looks_like_device_spreadsheet_ui(add));
        let change = "[@iid:98063412749627392|VM1]can you change that to \"Este\"";
        assert!(user_text_looks_like_device_spreadsheet_ui(change));
        let keys = "[@iid:98063412749627392|VM1]can you add it using mouse click and send key?";
        assert!(user_text_looks_like_device_spreadsheet_ui(keys));
    }

    #[test]
    fn shell_sendkeys_forbidden_on_sheets() {
        assert!(google_sheets_shell_command_forbidden(
            "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('Budi')"
        ));
    }

    #[test]
    fn shell_echo_script_blocked_on_sheets_ui_turn() {
        assert!(google_sheets_shell_blocked_on_ui_turn(
            "echo \"Adding 2 rows to the spreadsheet...\""
        ));
        assert!(!google_sheets_shell_blocked_on_ui_turn("start-process chrome"));
    }

    #[test]
    fn pixel_grid_batch_without_goto_detected() {
        let args = json!({
            "actions": [
                {"event_type": "click_and_type", "x": 0.06, "y": 0.5, "text": "Budi"}
            ]
        });
        assert!(google_sheets_device_input_uses_pixel_grid_without_goto(&args));
        let ok = json!({
            "actions": [
                {"event_type": "shortcut", "text": "ctrl+g"},
                {"event_type": "type_text", "text": "A2"},
                {"event_type": "shortcut", "text": "enter"},
                {"event_type": "type_text", "text": "Budi"}
            ]
        });
        assert!(!google_sheets_device_input_uses_pixel_grid_without_goto(&ok));
    }

    #[test]
    fn parent_turn_blocks_premature_success() {
        let goal = "google sheet terbuka tambahkan 3 data sample";
        let counts = ComputerUseToolCounts {
            device_input: 2,
            device_screenshot: 1,
        };
        assert!(!google_sheets_parent_turn_may_finish(
            goal,
            "Data sampel telah berhasil ditambahkan ke Google Sheet Anda.",
            counts,
            false,
            false,
            false,
        ));
    }

    #[test]
    fn parent_turn_blocks_unverified_bold() {
        let goal = "[@iid:98063412749627392] buat semua header bold";
        let counts = ComputerUseToolCounts {
            device_input: 3,
            device_screenshot: 2,
        };
        // Even if summary claims success and tool activity has inputs, it must block if bold_verified is false
        assert!(!google_sheets_parent_turn_may_finish(
            goal,
            "Header row (Nama, Alamat, Jenis Kelamin) berhasil dibuat tebal (bold).",
            counts,
            false,
            false,
            false,
        ));
        // Once bold_verified is true, it may finish
        assert!(google_sheets_parent_turn_may_finish(
            goal,
            "Header row (Nama, Alamat, Jenis Kelamin) berhasil dibuat tebal (bold).",
            counts,
            false,
            true,
            false,
        ));
    }

    #[test]
    fn parent_turn_blocks_row_insert_without_typing() {
        let goal = "[@iid:98063412749627392|VM1]tambahkan 2 baris data";
        let counts = ComputerUseToolCounts {
            device_input: 4,
            device_screenshot: 4,
        };
        // If has_typing is false, cannot finish
        assert!(!google_sheets_parent_turn_may_finish(
            goal,
            "2 baris data telah ditambahkan.",
            counts,
            false,
            false,
            false,
        ));
        // If summary falsely claims bold when bold_verified is false, cannot finish
        assert!(!google_sheets_parent_turn_may_finish(
            goal,
            "Header sudah ditebalkan (bold), dan 2 baris data telah ditambahkan.",
            counts,
            false,
            false,
            true,
        ));
        // Once has_typing is true and no unverified claims, may finish
        assert!(google_sheets_parent_turn_may_finish(
            goal,
            "2 baris data telah ditambahkan ke sheet.",
            counts,
            false,
            false,
            true,
        ));
    }
}
