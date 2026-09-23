// Thread-safe in-memory cache of skills synced from server.
// Loaded once on connect via ReqSkillList; updated on skill_put ack.
use c35_proto::Skill;
use std::sync::{Arc, RwLock};

pub type SkillStore = Arc<RwLock<Vec<Skill>>>;

pub fn new_store() -> SkillStore {
    Arc::new(RwLock::new(Vec::new()))
}

pub fn update_skill(store: &SkillStore, skill: Skill) {
    let mut guard = store.write().unwrap();
    if let Some(pos) = guard.iter().position(|s| s.id == skill.id) {
        guard[pos] = skill;
    } else {
        guard.push(skill);
    }
}

/// Find best matching skill for the given request.
/// Matches on: phrases_json keywords, target_app, url_pattern.
/// Returns Some(skill) if confidence >= threshold.
pub fn find_match(store: &SkillStore, prompt: &str, target_app: &str, url: &str) -> Option<Skill> {
    let guard = store.read().unwrap();
    let prompt_lower = prompt.to_lowercase();
    let target_lower = target_app.to_lowercase();
    let url_lower = url.to_lowercase();

    let mut best: Option<(&Skill, u32)> = None;

    for skill in guard.iter() {
        if !skill.auto_run || skill.deleted_ts_ms > 0 {
            continue;
        }
        let mut score: u32 = 0;

        // Target app match (strong signal)
        if !skill.target_app.is_empty()
            && target_lower.contains(&skill.target_app.to_lowercase())
        {
            score += 40;
        }

        // URL pattern match
        if !skill.url_pattern.is_empty()
            && url_lower.contains(&skill.url_pattern.to_lowercase())
        {
            score += 30;
        }

        // Phrase keyword match
        if let Ok(phrases) = serde_json::from_str::<Vec<String>>(&skill.phrases_json) {
            for phrase in &phrases {
                if prompt_lower.contains(&phrase.to_lowercase()) {
                    score += 20;
                    break;
                }
            }
        }

        if score >= 20 {
            if best.map_or(true, |(_, bs)| score > bs) {
                best = Some((skill, score));
            }
        }
    }

    best.map(|(s, _)| s.clone())
}
