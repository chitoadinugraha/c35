use c35_mod_site::grant::{site_role_allows, site_role_rank};
use c35_mod_site::{
    site_member_shift_ids_normalize,
    site_grant_list_ensure_owner, site_grant_role_staff_manage, site_grant_role_writable,
};
use c35_proto::SiteGrant;

#[test]
fn site_role_rank_order() {
    assert!(site_role_rank("owner") > site_role_rank("manage"));
    assert!(site_role_rank("manage") > site_role_rank("staff"));
    assert!(site_role_rank("staff") > site_role_rank("guest"));
    assert!(site_role_rank("guest") > site_role_rank("unknown"));
    assert_eq!(site_role_rank("unknown"), 0);
}

#[test]
fn site_role_allows_read_write() {
    assert!(site_role_allows("guest", false));
    assert!(!site_role_allows("guest", true));
    assert!(site_role_allows("staff", false));
    assert!(!site_role_allows("staff", true));
    assert!(site_role_allows("manage", true));
    assert!(!site_role_allows("", false));
}

#[test]
fn site_grant_role_writable_staff_manage_guest() {
    assert_eq!(site_grant_role_writable("staff").unwrap(), "staff");
    assert_eq!(site_grant_role_writable("Manage").unwrap(), "manage");
    assert_eq!(site_grant_role_writable("guest").unwrap(), "guest");
    assert!(site_grant_role_writable("owner").is_err());
    // Legacy name remains a thin wrapper over writable roles.
    assert_eq!(site_grant_role_staff_manage("Guest").unwrap(), "guest");
}

#[test]
fn site_grant_list_empty_staff_still_returns_owner() {
    let owner = SiteGrant {
        site_iid: 100,
        grantee_iid: 42,
        grantee_alien_id: "owner".into(),
        grantee_name: "Owner".into(),
        role: "owner".into(),
        is_owner: true,
        ..Default::default()
    };
    let grants = site_grant_list_ensure_owner(vec![], owner);
    assert_eq!(grants.len(), 1);
    assert!(grants[0].is_owner);
    assert_eq!(grants[0].grantee_iid, 42);
    assert_eq!(grants[0].role, "owner");
}

#[test]
fn site_grant_list_ensure_owner_dedupes_existing() {
    let owner = SiteGrant {
        site_iid: 100,
        grantee_iid: 42,
        role: "owner".into(),
        is_owner: true,
        ..Default::default()
    };
    let existing = SiteGrant {
        site_iid: 100,
        grantee_iid: 42,
        role: "owner".into(),
        is_owner: false,
        grantee_name: "Owner".into(),
        ..Default::default()
    };
    let grants = site_grant_list_ensure_owner(vec![existing], owner);
    assert_eq!(grants.len(), 1);
    assert!(grants[0].is_owner);
}

/// Integration: resolve by email (identity_provider) and alien_id. Needs YSQL.
#[tokio::test]
#[ignore]
async fn site_grantee_resolve_email_and_alien() {
    let pool = c35_store::pool_connect().await.expect("pool");
    let alien = format!("g1test{}", c35_store::snowflake_id());
    let email = format!("{alien}@example.com");
    let iid = c35_store::snowflake_id();

    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, alien_id, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'user', $2, 'G1 Test', $1, jsonb_build_object('email', $3::text), NOW(), NOW())
        "#,
    )
    .bind(iid)
    .bind(&alien)
    .bind(&email)
    .execute(&pool)
    .await
    .expect("insert identity");

    sqlx::query(
        r#"
        INSERT INTO ai.identity_provider
            (id, identity_iid, kind, identifier, is_verified, is_primary, meta, created_ts, updated_ts)
        VALUES ($1, $2, 'email', $3, true, true, '{}', NOW(), NOW())
        "#,
    )
    .bind(c35_store::snowflake_id())
    .bind(iid)
    .bind(&email)
    .execute(&pool)
    .await
    .expect("insert provider");

    let by_email = c35_mod_site::site_grantee_resolve(&pool, 0, "", &email)
        .await
        .expect("resolve email");
    assert_eq!(by_email, iid);

    let by_alien = c35_mod_site::site_grantee_resolve(&pool, 0, &alien, "")
        .await
        .expect("resolve alien");
    assert_eq!(by_alien, iid);

    let by_iid = c35_mod_site::site_grantee_resolve(&pool, iid, "", "")
        .await
        .expect("resolve iid");
    assert_eq!(by_iid, iid);

    // Cleanup soft-delete so re-runs stay unique.
    let _ = sqlx::query("UPDATE ai.identity_provider SET deleted_ts = NOW() WHERE identity_iid = $1")
        .bind(iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE ai.identity SET deleted_ts = NOW() WHERE id = $1")
        .bind(iid)
        .execute(&pool)
        .await;
}

/// Integration: transfer ownership demotes previous owner to manage. Needs YSQL.
#[tokio::test]
#[ignore]
async fn site_transfer_ownership_promotes_member() {
    let pool = c35_store::pool_connect().await.expect("pool");
    let owner_iid = c35_store::snowflake_id();
    let target_iid = c35_store::snowflake_id();
    let site_iid = c35_store::snowflake_id();
    let alien = format!("h3site{}", site_iid);

    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, alien_id, name, owner_iid, created_ts, updated_ts)
        VALUES
          ($1, 'user', NULL, 'H3 Owner', $1, NOW(), NOW()),
          ($2, 'user', NULL, 'H3 Target', $2, NOW(), NOW()),
          ($3, 'site', $4, 'H3 Site', $1, NOW(), NOW())
        "#,
    )
    .bind(owner_iid)
    .bind(target_iid)
    .bind(site_iid)
    .bind(&alien)
    .execute(&pool)
    .await
    .expect("insert identities");

    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, created_ts, updated_ts)
        VALUES ($1, $2, NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert site.config");

    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'staff', '{}', false, '{}', NOW(), NOW())
        "#,
    )
    .bind(c35_store::snowflake_id())
    .bind(site_iid)
    .bind(target_iid)
    .execute(&pool)
    .await
    .expect("insert staff grant");

    let res = c35_mod_site::site_transfer_ownership_rpc(
        &pool,
        owner_iid,
        c35_proto::ReqSiteTransferOwnership {
            site_iid,
            target_iid,
        },
    )
    .await
    .expect("transfer");
    assert!(res.ok);
    assert_eq!(res.new_owner_iid, target_iid);

    let new_owner: i64 = sqlx::query_scalar(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'site'",
    )
    .bind(site_iid)
    .fetch_one(&pool)
    .await
    .expect("identity owner");
    assert_eq!(new_owner, target_iid);

    let cfg_owner: i64 =
        sqlx::query_scalar("SELECT owner_iid FROM site.config WHERE site_iid = $1")
            .bind(site_iid)
            .fetch_one(&pool)
            .await
            .expect("config owner");
    assert_eq!(cfg_owner, target_iid);

    let target_role: String = sqlx::query_scalar(
        "SELECT role FROM ai.identity_grant WHERE resource_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(target_iid)
    .fetch_one(&pool)
    .await
    .expect("target role");
    assert_eq!(target_role, "owner");

    let prev_role: String = sqlx::query_scalar(
        "SELECT role FROM ai.identity_grant WHERE resource_iid = $1 AND grantee_iid = $2 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .bind(owner_iid)
    .fetch_one(&pool)
    .await
    .expect("prev owner role");
    assert_eq!(prev_role, "manage");

    // Non-owner cannot transfer.
    let denied = c35_mod_site::site_transfer_ownership(&pool, owner_iid, site_iid, owner_iid).await;
    assert!(denied.is_err());

    // Cleanup.
    let _ = sqlx::query("UPDATE ai.identity_grant SET deleted_ts = NOW() WHERE resource_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE site.config SET deleted_ts = NOW() WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE ai.identity SET deleted_ts = NOW() WHERE id = ANY($1)")
        .bind(vec![site_iid, owner_iid, target_iid])
        .execute(&pool)
        .await;
}

#[test]
fn site_member_shift_ids_normalize_trim_dedupe() {
    let raw = vec![
        "  b ".into(),
        "".into(),
        "a".into(),
        "b".into(),
        " a ".into(),
    ];
    assert_eq!(
        site_member_shift_ids_normalize(&raw),
        vec!["a".to_string(), "b".to_string()]
    );
    assert!(site_member_shift_ids_normalize(&[]).is_empty());
}

/// Integration: grant put replaces/clears member_shift; delete cleans shifts + soft-deletes faces.
#[tokio::test]
#[ignore]
async fn site_grant_put_member_shift_replace_clear_delete() {
    let pool = c35_store::pool_connect().await.expect("pool");
    let owner_iid = c35_store::snowflake_id();
    let grantee_iid = c35_store::snowflake_id();
    let site_iid = c35_store::snowflake_id();
    let alien = format!("h2site{}", site_iid);
    let shift_a = format!("sa-{}", site_iid);
    let shift_b = format!("sb-{}", site_iid);

    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, alien_id, name, owner_iid, created_ts, updated_ts)
        VALUES
          ($1, 'user', NULL, 'H2 Owner', $1, NOW(), NOW()),
          ($2, 'user', NULL, 'H2 Staff', $2, NOW(), NOW()),
          ($3, 'site', $4, 'H2 Site', $1, NOW(), NOW())
        "#,
    )
    .bind(owner_iid)
    .bind(grantee_iid)
    .bind(site_iid)
    .bind(&alien)
    .execute(&pool)
    .await
    .expect("insert identities");

    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, created_ts, updated_ts)
        VALUES ($1, $2, NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert site.config");

    for sid in [&shift_a, &shift_b] {
        sqlx::query(
            r#"
            INSERT INTO site.work_shift (site_iid, shift_id, name, attendance_method, is_active, sort_order, created_ts, updated_ts)
            VALUES ($1, $2, $2, 'button', true, 0, NOW(), NOW())
            "#,
        )
        .bind(site_iid)
        .bind(sid)
        .execute(&pool)
        .await
        .expect("insert work_shift");
    }

    // Replace with two shifts.
    c35_mod_site::site_grant_put(
        &pool,
        owner_iid,
        site_iid,
        grantee_iid,
        "staff",
        Some(&[shift_a.clone(), shift_b.clone()]),
    )
    .await
    .expect("put with shifts");

    let ids: Vec<String> = sqlx::query_scalar(
        "SELECT shift_id FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2 ORDER BY shift_id",
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_all(&pool)
    .await
    .expect("list shifts");
    assert_eq!(ids, vec![shift_a.clone(), shift_b.clone()]);

    // Unknown shift_id errors (and should not leave partial state from that call).
    let bad = c35_mod_site::site_grant_put(
        &pool,
        owner_iid,
        site_iid,
        grantee_iid,
        "staff",
        Some(&["no-such-shift".into()]),
    )
    .await;
    assert!(bad.is_err());

    // Clear via empty list.
    c35_mod_site::site_grant_put(
        &pool,
        owner_iid,
        site_iid,
        grantee_iid,
        "staff",
        Some(&[]),
    )
    .await
    .expect("clear shifts");
    let cleared: i64 = sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2",
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_one(&pool)
    .await
    .expect("count cleared");
    assert_eq!(cleared, 0);

    // Re-assign one shift + face, then delete grant cleans both.
    c35_mod_site::site_grant_put(
        &pool,
        owner_iid,
        site_iid,
        grantee_iid,
        "staff",
        Some(&[shift_a.clone()]),
    )
    .await
    .expect("reassign");

    let face_id = c35_store::snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO site.member_face
            (face_id, site_iid, grantee_iid, file_hash, embedding, model_version, is_active, sort_order, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'h2hash', '{}', 'none', true, 0, NOW(), NOW())
        "#,
    )
    .bind(face_id)
    .bind(site_iid)
    .bind(grantee_iid)
    .execute(&pool)
    .await
    .expect("insert face");

    c35_mod_site::site_grant_delete(&pool, owner_iid, site_iid, grantee_iid)
        .await
        .expect("delete grant");

    let after_del: i64 = sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM site.member_shift WHERE site_iid = $1 AND grantee_iid = $2",
    )
    .bind(site_iid)
    .bind(grantee_iid)
    .fetch_one(&pool)
    .await
    .expect("count after delete");
    assert_eq!(after_del, 0);

    let face_gone: bool = sqlx::query_scalar(
        "SELECT deleted_ts IS NOT NULL AND is_active = FALSE FROM site.member_face WHERE face_id = $1",
    )
    .bind(face_id)
    .fetch_one(&pool)
    .await
    .expect("face soft-deleted");
    assert!(face_gone);

    // Cleanup fixtures.
    let _ = sqlx::query("DELETE FROM site.member_face WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM site.member_shift WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM site.work_shift_slot WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("DELETE FROM site.work_shift WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE ai.identity_grant SET deleted_ts = NOW() WHERE resource_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE site.config SET deleted_ts = NOW() WHERE site_iid = $1")
        .bind(site_iid)
        .execute(&pool)
        .await;
    let _ = sqlx::query("UPDATE ai.identity SET deleted_ts = NOW() WHERE id = ANY($1)")
        .bind(vec![site_iid, owner_iid, grantee_iid])
        .execute(&pool)
        .await;
}
