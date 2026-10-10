/// Injected on Home compose via `wire:date_range` (`inst.core.date_range`).
pub const DATE_RANGE_INST: &str = r#"[DATE RANGE — tool params]
When a tool accepts a time window, use this object shape inside `params` (not separate tools per period):
- `range` (string, optional): named window — `today`, `yesterday`, `this_week`, `last_week`, `this_month`, `last_month`, `mtd`, `ytd`. Alias: `month_to_date` = `mtd`.
- `date_from` / `date_to` (string, optional): inclusive calendar days `YYYY-MM-DD` in the user's timezone when `tz` is set (else UTC).
- `time_from_ms` / `time_to_ms` (integer, optional): explicit UTC epoch milliseconds; if either is set, these win over `range` and `date_*`.
- `tz` (string, optional): IANA zone e.g. `Asia/Jakarta`. Omit on tool calls — the server defaults from user locale/prefs.

Map user language to `range` (examples): hari ini → `today`; kemarin → `yesterday`; minggu ini → `this_week`; minggu lalu → `last_week`; bulan ini / MTD → `mtd` or `this_month`; bulan lalu → `last_month`; tahun ini → `ytd`. Custom spans → `date_from` + `date_to` or ms bounds.
Do not invent SQL or ad-hoc date fields. Same shape for `site.query.run`, `site.tx.list`, consumption/expense day tools, and future readonly queries."#;

pub fn date_range_prompt_block(user_tz: &str) -> String {
    let tz = user_tz.trim();
    let tz_note = if tz.is_empty() { "UTC (default)" } else { tz };
    format!("{DATE_RANGE_INST}\n\nDefault `tz` for this turn when omitted: {tz_note}.")
}
