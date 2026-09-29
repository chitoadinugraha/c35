use anyhow::{bail, Result};
use c35_proto::SkillStep;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

/// In-memory teach step before proto mapping.
#[derive(Clone, Debug)]
pub struct TeachStepRecord {
    pub ord: i32,
    pub kind: String,
    pub label: String,
    pub ax_target_json: String,
    pub tape_local_only_json: String,
}

#[derive(Clone, Debug, Default)]
pub struct TeachStatus {
    pub recording: bool,
    pub title: String,
    pub steps: Vec<TeachStepRecord>,
    pub duration_sec: u64,
    pub last_label: String,
}

struct TeachState {
    title: String,
    recording: bool,
    steps: Vec<TeachStepRecord>,
    typing: String,
    control: String,
    window: String,
    is_password: bool,
    last_type_at: Option<Instant>,
    started_at: Option<Instant>,
    next_ord: i32,
}

impl TeachState {
    fn idle() -> Self {
        Self {
            title: String::new(),
            recording: false,
            steps: Vec::new(),
            typing: String::new(),
            control: String::new(),
            window: String::new(),
            is_password: false,
            last_type_at: None,
            started_at: None,
            next_ord: 0,
        }
    }
}

static TEACH: OnceLock<Mutex<TeachState>> = OnceLock::new();
static SKIP_HOOK: AtomicBool = AtomicBool::new(false);

/// While handling WebRTC remote input, low-level mouse hooks must not duplicate steps.
pub fn teach_skip_hooks(skip: bool) {
    SKIP_HOOK.store(skip, Ordering::SeqCst);
}

pub fn teach_hooks_skipped() -> bool {
    SKIP_HOOK.load(Ordering::SeqCst)
}

fn state() -> &'static Mutex<TeachState> {
    TEACH.get_or_init(|| Mutex::new(TeachState::idle()))
}

type OnStart = fn(&str);
type OnStop = fn();
type OnLast = fn(i32, &str);

struct Platform {
    on_start: OnStart,
    on_stop: OnStop,
    on_last: OnLast,
}

static PLATFORM: OnceLock<Platform> = OnceLock::new();

/// Windows agent registers overlay + low-level hooks at startup.
pub fn register_platform(on_start: OnStart, on_stop: OnStop, on_last: OnLast) {
    let _ = PLATFORM.set(Platform {
        on_start,
        on_stop,
        on_last,
    });
}

pub fn teach_is_recording() -> bool {
    state().lock().unwrap().recording
}

pub fn teach_status() -> TeachStatus {
    flush_typing_if_idle();
    let g = state().lock().unwrap();
    let duration_sec = g
        .started_at
        .map(|t| t.elapsed().as_secs())
        .unwrap_or(0);
    let last_label = g.steps.last().map(|s| s.label.clone()).unwrap_or_default();
    TeachStatus {
        recording: g.recording,
        title: g.title.clone(),
        steps: g.steps.clone(),
        duration_sec,
        last_label,
    }
}

pub fn teach_start(title: &str) -> Result<()> {
    let title = title.trim();
    if title.is_empty() {
        bail!("teach title required");
    }
    {
        let mut g = state().lock().unwrap();
        *g = TeachState::idle();
        g.title = title.to_string();
        g.recording = true;
        g.started_at = Some(Instant::now());
    }
    if let Some(p) = PLATFORM.get() {
        (p.on_start)(title);
    }
    Ok(())
}

pub fn teach_stop() -> Result<Vec<TeachStepRecord>> {
    let steps = {
        let mut g = state().lock().unwrap();
        if !g.recording {
            return Ok(g.steps.clone());
        }
        commit_typing(&mut g, false);
        g.recording = false;
        g.steps.clone()
    };
    if let Some(p) = PLATFORM.get() {
        (p.on_stop)();
    }
    Ok(steps)
}

/// Viewer disconnected without save — stop overlay and discard in-memory tape.
pub fn teach_discard() {
    let was_recording = {
        let mut g = state().lock().unwrap();
        let was = g.recording;
        *g = TeachState::idle();
        was
    };
    if was_recording {
        if let Some(p) = PLATFORM.get() {
            (p.on_stop)();
        }
    }
}

pub fn teach_steps_to_proto(steps: &[TeachStepRecord]) -> Vec<SkillStep> {
    steps
        .iter()
        .map(|s| SkillStep {
            ord: s.ord,
            kind: s.kind.clone(),
            label: s.label.clone(),
            ax_target_json: s.ax_target_json.clone(),
            tape_local_only_json: s.tape_local_only_json.clone(),
            ..Default::default()
        })
        .collect()
}

// ============================================================= Recording (hooks + remote input)
pub fn teach_click_label(window: &str, name: &str) -> String {
    let control = if name.trim().is_empty() {
        "a control"
    } else {
        name.trim()
    };
    let w = window.trim();
    if w.is_empty() {
        format!("Click {control}")
    } else {
        format!("In {w}, click {control}")
    }
}

pub fn teach_type_label(
    window: &str,
    field: &str,
    text: &str,
    is_password: bool,
    enter: bool,
) -> String {
    let field = if field.trim().is_empty() {
        "the field"
    } else {
        field.trim()
    };
    let verb = if is_password {
        format!("fill password in {field}")
    } else if text.len() > 40 {
        format!("fill {field} with text")
    } else {
        format!("fill {field} with \"{text}\"")
    };
    let loc = if window.trim().is_empty() {
        let mut c = verb.chars();
        match c.next() {
            Some(ch) => format!("{}{}", ch.to_uppercase(), c.as_str()),
            None => verb,
        }
    } else {
        format!("In {}, {verb}", window.trim())
    };
    if enter {
        format!("{loc}, then press Enter")
    } else {
        loc
    }
}

pub fn teach_record_click(x: i32, y: i32, window: &str, control: &str) {
    let mut g = state().lock().unwrap();
    if !g.recording {
        return;
    }
    commit_typing(&mut g, false);
    g.next_ord += 1;
    let ord = g.next_ord;
    g.control = control.to_string();
    g.window = window.to_string();
    let label = teach_click_label(window, control);
    let (nx, ny) = pixel_to_norm(x, y);
    let ax_target_json = serde_json::json!({
        "x": nx,
        "y": ny,
        "center_x": nx,
        "center_y": ny,
        "pixel_x": x,
        "pixel_y": y,
        "window": window,
        "mark": control,
    })
    .to_string();
    g.steps.push(TeachStepRecord {
        ord,
        kind: "click".into(),
        label: label.clone(),
        ax_target_json,
        tape_local_only_json: String::new(),
    });
    drop(g);
    overlay_last(ord, &label);
}

pub fn teach_record_click_kind(kind: &str, x: i32, y: i32, window: &str, control: &str) {
    let mut g = state().lock().unwrap();
    if !g.recording {
        return;
    }
    commit_typing(&mut g, false);
    g.next_ord += 1;
    let ord = g.next_ord;
    let label = match kind {
        "right_click" => format!("Right-click {}", if control.is_empty() { "control" } else { control }),
        "double_click" => teach_click_label(window, control).replace("click", "double-click"),
        _ => teach_click_label(window, control),
    };
    let (nx, ny) = pixel_to_norm(x, y);
    let ax_target_json = serde_json::json!({
        "x": nx,
        "y": ny,
        "center_x": nx,
        "center_y": ny,
        "pixel_x": x,
        "pixel_y": y,
        "window": window,
        "mark": control,
    })
    .to_string();
    g.steps.push(TeachStepRecord {
        ord,
        kind: kind.to_string(),
        label: label.clone(),
        ax_target_json,
        tape_local_only_json: String::new(),
    });
    drop(g);
    overlay_last(ord, &label);
}

pub fn teach_key_event(vk: u32, ch: &str) -> bool {
    if vk == 0x78 || vk == 0x1B {
        let _ = teach_stop();
        return true;
    }
    let mut g = state().lock().unwrap();
    if !g.recording {
        return false;
    }
    if vk == 0x0D {
        commit_typing(&mut g, true);
        return false;
    }
    if vk == 0x08 {
        if !g.is_password {
            g.typing.pop();
        }
        return false;
    }
    if ch.is_empty() {
        return false;
    }
    if !g.is_password {
        g.typing.push_str(ch);
    }
    g.last_type_at = Some(Instant::now());
    let ghost = if g.is_password {
        format!(
            "Typing password in {}...",
            if g.control.is_empty() {
                "the field"
            } else {
                &g.control
            }
        )
    } else {
        format!(
            "Typing in {}...",
            if g.control.is_empty() {
                "the field"
            } else {
                &g.control
            }
        )
    };
    let ord = g.next_ord.max(1);
    drop(g);
    overlay_last(ord, &ghost);
    false
}

pub fn teach_focus_field(window: &str, control: &str, is_password: bool) {
    let mut g = state().lock().unwrap();
    if !g.recording {
        return;
    }
    g.window = window.to_string();
    if !control.trim().is_empty() {
        g.control = control.to_string();
    }
    if is_password {
        g.is_password = true;
    }
}

fn commit_typing(g: &mut TeachState, enter: bool) {
    if g.typing.is_empty() && !g.is_password {
        return;
    }
    g.next_ord += 1;
    let ord = g.next_ord;
    let name = if g.control.is_empty() {
        "the field".into()
    } else {
        g.control.clone()
    };
    let text_to_label = if g.is_password { "" } else { &g.typing };
    let label = teach_type_label(&g.window, &name, text_to_label, g.is_password, enter);
    let tape_local_only_json = if g.is_password {
        serde_json::json!({
            "field": name,
            "window": g.window,
            "is_password": true,
            "enter": enter,
        })
    } else {
        serde_json::json!({
            "field": name,
            "window": g.window,
            "text": g.typing,
            "is_password": false,
            "enter": enter,
        })
    }
    .to_string();
    g.steps.push(TeachStepRecord {
        ord,
        kind: "type".into(),
        label: label.clone(),
        ax_target_json: String::new(),
        tape_local_only_json,
    });
    g.typing.clear();
    g.is_password = false;
    g.last_type_at = None;
    overlay_last(ord, &label);
}

fn flush_typing_if_idle() {
    let mut g = state().lock().unwrap();
    if g.typing.is_empty() && !g.is_password {
        return;
    }
    if g
        .last_type_at
        .map(|t| t.elapsed() >= Duration::from_millis(500))
        .unwrap_or(false)
    {
        commit_typing(&mut g, false);
    }
}

fn overlay_last(ord: i32, label: &str) {
    if let Some(p) = PLATFORM.get() {
        (p.on_last)(ord, label);
    }
}

fn pixel_to_norm(x: i32, y: i32) -> (f64, f64) {
    let w = screen_w().max(1) as f64;
    let h = screen_h().max(1) as f64;
    ((x as f64 / w).clamp(0.0, 1.0), (y as f64 / h).clamp(0.0, 1.0))
}

#[cfg(windows)]
fn screen_w() -> i32 {
    use windows::Win32::UI::WindowsAndMessaging::{GetSystemMetrics, SM_CXSCREEN};
    unsafe { GetSystemMetrics(SM_CXSCREEN) }
}

#[cfg(windows)]
fn screen_h() -> i32 {
    use windows::Win32::UI::WindowsAndMessaging::{GetSystemMetrics, SM_CYSCREEN};
    unsafe { GetSystemMetrics(SM_CYSCREEN) }
}

#[cfg(not(windows))]
fn screen_w() -> i32 {
    1920
}

#[cfg(not(windows))]
fn screen_h() -> i32 {
    1080
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Mutex;

    static TEST_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn teach_start_stop_empty_steps() {
        let _g = TEST_LOCK.lock().unwrap();
        let _ = teach_stop();
        let _ = teach_start("Demo");
        assert!(teach_is_recording());
        let st = teach_status();
        assert_eq!(st.title, "Demo");
        assert!(st.steps.is_empty());
        let steps = teach_stop().unwrap();
        assert!(!teach_is_recording());
        assert!(steps.is_empty());
    }

    #[test]
    fn teach_click_and_type_labels() {
        let _g = TEST_LOCK.lock().unwrap();
        let _ = teach_stop();
        let _ = teach_start("T");
        teach_record_click(100, 200, "Notepad", "Save");
        teach_focus_field("Notepad", "Body", false);
        assert!(!teach_key_event(b'a' as u32, "a"));
        assert!(!teach_key_event(b'b' as u32, "b"));
        let steps = teach_stop().unwrap();
        assert_eq!(steps.len(), 2);
        assert_eq!(steps[0].kind, "click");
        assert!(steps[0].label.contains("Save"));
        assert_eq!(steps[1].kind, "type");
        assert!(steps[1].label.contains("Body"));
    }
}
