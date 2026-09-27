use std::collections::VecDeque;
use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use tracing::field::{Field, Visit};
use tracing::Level;
use tracing_subscriber::layer::Context;
use tracing_subscriber::Layer;

const CAP: usize = 3000;

#[derive(Clone, Debug)]
pub struct LogLine {
    pub ts_ms: u64,
    pub ymd: (i32, u32, u32),
    pub level: u8,
    pub topic: String,
    pub text: String,
}

fn ring() -> &'static Mutex<VecDeque<LogLine>> {
    static RING: OnceLock<Mutex<VecDeque<LogLine>>> = OnceLock::new();
    RING.get_or_init(|| Mutex::new(VecDeque::with_capacity(512)))
}

fn level_byte(level: &Level) -> u8 {
    match *level {
        Level::ERROR => 3,
        Level::WARN => 2,
        Level::INFO => 1,
        _ => 0,
    }
}

fn local_ymd_now() -> (i32, u32, u32) {
    #[cfg(windows)]
    {
        use windows::Win32::System::SystemInformation::GetLocalTime;
        let st = unsafe { GetLocalTime() };
        (st.wYear as i32, st.wMonth as u32, st.wDay as u32)
    }
    #[cfg(not(windows))]
    {
        let _ = ();
        (1970, 1, 1)
    }
}

pub fn push_line(level: Level, topic: &str, text: &str) {
    if matches!(level, Level::TRACE | Level::DEBUG) {
        return;
    }
    let ts_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);
    let line = LogLine {
        ts_ms,
        ymd: local_ymd_now(),
        level: level_byte(&level),
        topic: topic.to_string(),
        text: text.to_string(),
    };
    let Ok(mut q) = ring().lock() else {
        return;
    };
    if q.len() >= CAP {
        q.pop_front();
    }
    q.push_back(line);
}

pub fn lines_today() -> Vec<LogLine> {
    let today = local_ymd_now();
    ring()
        .lock()
        .map(|q| q.iter().filter(|l| l.ymd == today).cloned().collect())
        .unwrap_or_default()
}

pub fn lines_today_local() -> Vec<LogLine> {
    lines_today()
}

pub fn tail(n: usize) -> Vec<LogLine> {
    let Ok(q) = ring().lock() else {
        return Vec::new();
    };
    let start = q.len().saturating_sub(n);
    q.iter().skip(start).cloned().collect()
}

struct EventVisitor {
    message: String,
    topic: String,
}

impl EventVisitor {
    fn new() -> Self {
        Self {
            message: String::new(),
            topic: String::new(),
        }
    }
}

impl Visit for EventVisitor {
    fn record_str(&mut self, field: &Field, value: &str) {
        match field.name() {
            "message" => self.message = value.to_string(),
            "topic" => self.topic = value.to_string(),
            _ => {}
        }
    }

    fn record_debug(&mut self, field: &Field, value: &dyn std::fmt::Debug) {
        if field.name() == "message" && self.message.is_empty() {
            self.message = format!("{:?}", value);
            if self.message.len() >= 2
                && self.message.starts_with('"')
                && self.message.ends_with('"')
            {
                self.message = self.message[1..self.message.len() - 1].to_string();
            }
        }
    }
}

pub struct LogRingLayer;

pub fn layer() -> LogRingLayer {
    LogRingLayer
}

impl<S> Layer<S> for LogRingLayer
where
    S: tracing::Subscriber,
{
    fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>) {
        let level = *event.metadata().level();
        let mut visitor = EventVisitor::new();
        event.record(&mut visitor);
        let text = if visitor.message.is_empty() {
            event.metadata().name().to_string()
        } else {
            visitor.message
        };
        let topic = if visitor.topic.is_empty() {
            event.metadata().target().to_string()
        } else {
            visitor.topic
        };
        push_line(level, &topic, &text);
    }
}

pub fn format_line(line: &LogLine) -> String {
    let lvl = match line.level {
        3 => "ERR",
        2 => "WRN",
        1 => "INF",
        _ => "   ",
    };
    let h = (line.ts_ms / 3_600_000) % 24;
    let m = (line.ts_ms / 60_000) % 60;
    let s = (line.ts_ms / 1_000) % 60;
    format!(
        "{:02}:{:02}:{:02} {} {:<24} {}",
        h, m, s, lvl, truncate(&line.topic, 24), line.text
    )
}

fn truncate(s: &str, max: usize) -> String {
    if s.len() <= max {
        s.to_string()
    } else {
        format!("{}...", s.chars().take(max.saturating_sub(1)).collect::<String>())
    }
}