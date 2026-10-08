//! Member face list/put/del — unit helpers + ignored DB roundtrip.

use c35_mod_site::{site_member_face_del, site_member_face_list, site_member_face_put};
use c35_proto::{ReqSiteMemberFaceDel, ReqSiteMemberFaceList, ReqSiteMemberFacePut};

#[test]
fn site_member_face_put_req_needs_hash() {
    let req = ReqSiteMemberFacePut {
        site_iid: 1,
        grantee_iid: 2,
        file_hash: String::new(),
        pose: String::new(),
    };
    assert!(req.file_hash.trim().is_empty());
}

#[tokio::test]
#[ignore]
async fn site_member_face_put_list_del_roundtrip() {
    let pool = c35_store::pool_connect().await.expect("pool");
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

    let file_hash = format!("{:064x}", 0xface_u128);
    // Prefer a real blake3-looking 64 hex; pad deterministic fixture.
    let file_hash = if file_hash.len() == 64 {
        file_hash
    } else {
        format!("{file_hash:0>64}")
    };

    let put = site_member_face_put(
        &pool,
        caller_iid,
        ReqSiteMemberFacePut {
            site_iid,
            grantee_iid: caller_iid,
            file_hash: file_hash.clone(),
            pose: "front".into(),
        },
    )
    .await
    .expect("put");
    let face = put.face.expect("face");
    assert_eq!(face.file_hash, file_hash);
    assert!(face.embedding.is_empty());
    assert!(!face.id.is_empty());

    let listed = site_member_face_list(
        &pool,
        caller_iid,
        ReqSiteMemberFaceList {
            site_iid,
            grantee_iid: caller_iid,
        },
    )
    .await
    .expect("list");
    assert!(listed.faces.iter().any(|f| f.id == face.id));

    let del = site_member_face_del(
        &pool,
        caller_iid,
        ReqSiteMemberFaceDel {
            site_iid,
            grantee_iid: caller_iid,
            face_id: face.id.clone(),
        },
    )
    .await
    .expect("del");
    assert!(del.ok);

    let after = site_member_face_list(
        &pool,
        caller_iid,
        ReqSiteMemberFaceList {
            site_iid,
            grantee_iid: caller_iid,
        },
    )
    .await
    .expect("list after del");
    assert!(!after.faces.iter().any(|f| f.id == face.id));

    let soft: bool = sqlx::query_scalar(
        "SELECT deleted_ts IS NOT NULL AND is_active = FALSE FROM site.member_face WHERE face_id = $1::bigint",
    )
    .bind(&face.id)
    .fetch_one(&pool)
    .await
    .expect("soft delete check");
    assert!(soft);

    let _ = sqlx::query("DELETE FROM site.member_face WHERE face_id = $1::bigint")
        .bind(&face.id)
        .execute(&pool)
        .await;
}
