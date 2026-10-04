/// Pick the site ids a catalog read or write may use.
///
/// Order: explicit args (must stay inside a non-empty mention), else the mention, else every grant.
pub fn site_scope_pick(mentioned: &[i64], granted: &[i64], arg_iids: &[i64]) -> Result<Vec<i64>, String> {
    if !arg_iids.is_empty() {
        if !mentioned.is_empty() && arg_iids.iter().any(|id| !mentioned.contains(id)) {
            return Err("site_iid is outside the mentioned sites".to_string());
        }
        return Ok(iids_dedup(arg_iids));
    }
    if !mentioned.is_empty() {
        return Ok(mentioned.to_vec());
    }
    Ok(granted.to_vec())
}

fn iids_dedup(ids: &[i64]) -> Vec<i64> {
    ids.iter().copied().fold(Vec::new(), |mut acc, iid| {
        if !acc.contains(&iid) {
            acc.push(iid);
        }
        acc
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn site_scope_pick_mentioned_ignores_other_grants() {
        let mentioned = [111_i64];
        let granted = [111, 222];
        assert_eq!(site_scope_pick(&mentioned, &granted, &[]).unwrap(), vec![111]);
    }

    #[test]
    fn site_scope_pick_no_mention_uses_all_granted() {
        assert_eq!(site_scope_pick(&[], &[111, 222], &[]).unwrap(), vec![111, 222]);
    }

    #[test]
    fn site_scope_pick_arg_outside_mention_errors() {
        let err = site_scope_pick(&[111], &[111, 222], &[222]).unwrap_err();
        assert!(err.contains("outside the mentioned sites"));
    }

    #[test]
    fn site_scope_pick_empty_is_ok() {
        assert_eq!(site_scope_pick(&[], &[], &[]).unwrap(), Vec::<i64>::new());
    }
}
