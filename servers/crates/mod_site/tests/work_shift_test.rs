//! Work-shift list/put - unit helpers + ignored DB roundtrip.

use c35_mod_site::{site_work_shift_list, site_work_shift_put};
use c35_proto::{
    ReqSiteWorkShiftList, ReqSiteWorkShiftPut, SiteWorkShift, SiteWorkShiftSlot,
};

#[test]
fn site_work_shift_empty_request_has_no_shifts() {
    let req = ReqSiteWorkShiftPut {
        site_iid: 1,
        shifts: vec![],
    };
    assert!(req.shifts.is_empty());
}

#[tokio::test]
#[ignore]
async fn site_work_shift_list_empty_then_put_roundtrip() {
    let pool = c35_store::pool_connect().await.expect("pool");
    // Disposable site owned by automated-tester (33000).
    let caller_iid: i64 = 33000;
    let site_iid: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.identity
        WHERE kind = 'site' AND owner_iid = $1 AND deleted_ts IS NULL
        ORDER BY id
        LIMIT 1
        "#,
    )
    .bind(caller_iid)
    .fetch_optional(&pool)
    .await
    .expect("site lookup");
    let Some(site_iid) = site_iid else {
        eprintln!("skip: no site owned by {caller_iid}");
        return;
    };

    site_work_shift_put(
        &pool,
        caller_iid,
        ReqSiteWorkShiftPut {
            site_iid,
            shifts: vec![],
        },
    )
    .await
    .expect("clear");
    let empty = site_work_shift_list(
        &pool,
        caller_iid,
        ReqSiteWorkShiftList { site_iid },
    )
    .await
    .expect("list after clear");
    assert!(
        empty.shifts.is_empty(),
        "expected empty after clear, got {:?}",
        empty.shifts
    );

    let shift_id = format!("ws-test-{}", now_ms());
    site_work_shift_put(
        &pool,
        caller_iid,
        ReqSiteWorkShiftPut {
            site_iid,
            shifts: vec![SiteWorkShift {
                site_iid,
                id: shift_id.clone(),
                name: "Morning".into(),
                attendance_method: "button".into(),
                slots: vec![SiteWorkShiftSlot {
                    id: "slot-a".into(),
                    start_day: 1,
                    start_min: 540,
                    end_day: 1,
                    end_min: 720,
                }],
                created_ts_ms: 0,
                updated_ts_ms: 0,
                deleted_ts_ms: 0,
            }],
        },
    )
    .await
    .expect("put");

    let listed = site_work_shift_list(
        &pool,
        caller_iid,
        ReqSiteWorkShiftList { site_iid },
    )
    .await
    .expect("list after put");
    assert_eq!(listed.shifts.len(), 1);
    assert_eq!(listed.shifts[0].id, shift_id);
    assert_eq!(listed.shifts[0].name, "Morning");
    assert_eq!(listed.shifts[0].slots.len(), 1);
    assert_eq!(listed.shifts[0].slots[0].start_min, 540);

    site_work_shift_put(
        &pool,
        caller_iid,
        ReqSiteWorkShiftPut {
            site_iid,
            shifts: vec![],
        },
    )
    .await
    .expect("clear again");
}

fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}
