//! Guest open-hours from `meta.open_hours` (CSA slot shape) — matches Flutter `site_schedule*.dart`.

use chrono::{Datelike, Timelike, Utc};
use serde_json::Value;

const WEEKDAYS_LONG: [&str; 7] = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
];

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct GuestScheduleSlot {
    pub start_day: i32,
    pub start_min: i32,
    pub end_day: i32,
    pub end_min: i32,
}

pub fn slots_from_meta(meta: &Value) -> Vec<GuestScheduleSlot> {
    let Some(items) = meta.get("open_hours").and_then(|v| v.as_array()) else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for item in items {
        let Some(m) = item.as_object() else {
            continue;
        };
        out.push(GuestScheduleSlot {
            start_day: int_field(m, "startDay", 0).clamp(0, 6),
            start_min: int_field(m, "startMin", 9 * 60).clamp(0, 1439),
            end_day: int_field(m, "endDay", 0).clamp(0, 6),
            end_min: int_field(m, "endMin", 17 * 60).clamp(0, 1439),
        });
    }
    out.sort_by_key(|s| s.start_day * 1440 + s.start_min);
    out
}

fn int_field(m: &serde_json::Map<String, Value>, key: &str, default: i32) -> i32 {
    m.get(key)
        .and_then(|v| v.as_i64())
        .map(|n| n as i32)
        .unwrap_or(default)
}

fn format_min(min: i32) -> String {
    let m = min.clamp(0, 1439);
    format!("{:02}:{:02}", m / 60, m % 60)
}

fn week_min(day: i32, min: i32) -> i32 {
    day.clamp(0, 6) * 1440 + min.clamp(0, 1439)
}

fn slot_segments(slot: &GuestScheduleSlot) -> Vec<(i32, i32, i32)> {
    let sd = slot.start_day.clamp(0, 6);
    let ed = slot.end_day.clamp(0, 6);
    let sm = slot.start_min.clamp(0, 1439);
    let em = slot.end_min.clamp(0, 1439);

    if ed > sd && em > sm {
        return (sd..=ed).map(|d| (d, sm, em)).collect();
    }
    if ed == sd {
        if em > sm {
            return vec![(sd, sm, em)];
        }
        if em < sm {
            return vec![(sd, sm, 1440), ((sd + 1) % 7, 0, em)];
        }
        return Vec::new();
    }

    let start = week_min(sd, sm);
    let mut end = week_min(ed, em);
    if end <= start {
        end += 7 * 1440;
    }
    let mut out = Vec::new();
    let mut pos = start;
    while pos < end {
        let day = (pos / 1440) % 7;
        let day_base = day * 1440;
        let seg_start = pos - day_base;
        let seg_end = if end < day_base + 1440 {
            end - day_base
        } else {
            1440
        };
        if seg_end > seg_start {
            out.push((day, seg_start, seg_end));
        }
        pos = day_base + 1440;
    }
    out
}

fn slot_ranges(slots: &[GuestScheduleSlot]) -> Vec<(i32, i32)> {
    let mut ranges = Vec::new();
    for slot in slots {
        for (day, start, end) in slot_segments(slot) {
            ranges.push((day * 1440 + start, day * 1440 + end));
        }
    }
    ranges.sort_by_key(|r| r.0);
    ranges
}

pub fn schedule_status(slots: &[GuestScheduleSlot]) -> (bool, String) {
    if slots.is_empty() {
        return (false, "Closed".into());
    }
    let now = Utc::now();
    let dow = now.weekday().num_days_from_monday() as i32;
    let now_min = dow * 1440 + now.hour() as i32 * 60 + now.minute() as i32;
    let week = 7 * 1440;

    let mut ranges = slot_ranges(slots);
    let next_week = ranges
        .iter()
        .map(|(s, e)| (s + week, e + week))
        .collect::<Vec<_>>();
    ranges.extend(next_week);

    for (start, end) in &ranges {
        if now_min >= *start && now_min < *end {
            return (true, "Open".into());
        }
    }

    let next = ranges.iter().find(|(start, _)| *start > now_min);
    let Some((next_start, _)) = next else {
        return (false, "Closed".into());
    };

    let delta = *next_start - now_min;
    if delta < 24 * 60 {
        if delta < 60 {
            let m = delta.max(1);
            return (false, format!("Open in {m} min"));
        }
        let h = ((delta as f64) / 60.0).round().clamp(1.0, 23.0) as i32;
        return (
            false,
            if h == 1 {
                "Open in 1 hour".into()
            } else {
                format!("Open in {h} hours")
            },
        );
    }
    let day = (*next_start / 1440) % 7;
    (
        false,
        format!("Open next {}", WEEKDAYS_LONG[day as usize]),
    )
}

pub fn hours_panel_rows(slots: &[GuestScheduleSlot]) -> Vec<(String, String, String)> {
    slots
        .iter()
        .map(|slot| {
            let day = WEEKDAYS_LONG[slot.start_day.clamp(0, 6) as usize].to_string();
            (
                day,
                format_min(slot.start_min),
                format_min(slot.end_min),
            )
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn slots_from_meta_parses_csa_shape() {
        let meta = json!({
            "open_hours": [{
                "id": "slot-1",
                "startDay": 0,
                "startMin": 540,
                "endDay": 0,
                "endMin": 1020
            }]
        });
        let slots = slots_from_meta(&meta);
        assert_eq!(slots.len(), 1);
        assert_eq!(slots[0].start_min, 540);
        let rows = hours_panel_rows(&slots);
        assert_eq!(rows[0].1, "09:00");
        assert_eq!(rows[0].2, "17:00");
    }

    #[test]
    fn schedule_status_label_non_empty() {
        let meta = json!({
            "open_hours": [{
                "startDay": 0,
                "startMin": 540,
                "endDay": 0,
                "endMin": 1020
            }]
        });
        let slots = slots_from_meta(&meta);
        let (_, label) = schedule_status(&slots);
        assert!(!label.is_empty());
    }
}
