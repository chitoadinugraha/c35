//! Canonical date / time-range wire format for tool `params` and server parsers.
//! Spec: `_/specs/time-range.md`.

mod inst;
mod resolve;
mod tz;

pub use inst::{date_range_prompt_block, DATE_RANGE_INST};
pub use resolve::{
    date_range_from_params, date_range_from_params_at, named_range_at, range_key_normalize,
    wire_from_params, DateRangeResolved, DateRangeWire,
};
pub use tz::{parse_tz, timezone_default_from_locale};
