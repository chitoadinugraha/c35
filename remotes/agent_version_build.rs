// Included from c_remote_windows/build.rs and c_remote_browser/build.rs.
use std::env;
use std::fs;
use std::path::PathBuf;

pub fn embed_agent_version(relative_version_path: &str) {
    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let version_path = manifest.join(relative_version_path);
    let raw = fs::read_to_string(&version_path)
        .unwrap_or_else(|e| panic!("read {}: {e}", version_path.display()));
    let line = raw.lines().next().unwrap_or("0.0.0+0").trim();
    let (name, build) = line
        .split_once('+')
        .map(|(n, b)| (n.trim(), b.trim()))
        .unwrap_or((line, "0"));
    let build_num: i64 = build.parse().unwrap_or(0);
    if name.is_empty() || build_num <= 0 {
        panic!(
            "invalid {} (expected NAME+BUILD): {line}",
            version_path.display()
        );
    }
    let middle = name
        .split('.')
        .nth(1)
        .and_then(|s| s.parse::<i64>().ok());
    if middle != Some(build_num) {
        panic!(
            "version middle segment must match +BUILD (expected 1.N.0+N, got {name}+{build_num})"
        );
    }
    let out = PathBuf::from(env::var("OUT_DIR").unwrap()).join("agent_version.rs");
    fs::write(
        &out,
        format!(
            r#"pub const AGENT_VERSION_NAME: &str = "{name}";
pub const AGENT_BUILD: i64 = {build_num};
"#,
        ),
    )
    .unwrap();
    println!("cargo:rerun-if-changed={}", version_path.display());
}