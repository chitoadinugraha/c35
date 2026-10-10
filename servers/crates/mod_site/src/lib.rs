mod cloudflare_registrar;
mod collection_def;

pub use cloudflare_registrar::{
    cf_dns_cname_grey, cf_domain_check, cf_domain_register, cf_domain_search, registrar_config,
    CfRegistration, DomainHit,
};
pub mod doc;
pub mod grant;
mod http;
mod commerce_boot;
pub mod guest_design;
mod guest_product;
mod guest_reservation;
mod product_design;
mod product_icon;
mod product_icon_svg;
pub mod render;
mod rows;
mod site_config;
mod site_contact;
mod site_link;
mod site_post;
mod dns_verify;
mod site_domain;
mod site_domain_buy;
mod site_grant;
mod site_hr;
mod site_draft;
mod site_boot;
mod site_handle;
mod platform_site;
mod site_ids;
mod site_list;
mod site_object;
mod site_preview;
mod site_product;
mod site_queue;
mod site_publish;
pub mod query;
mod sync;
mod sync_push;
mod tls_sync;
mod ts;
pub mod slug;

pub use slug::{site_slug_ensure_unique, site_slug_generate};

pub use collection_def::{collection_def_list, collection_def_list_rpc, collection_def_list_static};
pub use http::{host_is_api, host_is_primary, site_render_router, try_custom_domain_root};
pub use site_config::{
    site_capability_check, site_capability_enabled, site_capabilities_get, site_config_put,
};
pub use site_contact::{guest_contact_put, site_contact_list, site_contact_put, site_contact_upsert};
pub use site_link::{
    site_link_boot_rows, site_link_delete, site_link_list, site_link_put, site_link_upsert,
};
pub use site_post::{
    post_boot_summary_json, site_post_boot_summaries, site_post_delete, site_post_get_storefront,
    site_post_list, site_post_put, site_post_storefront_ids, site_post_upsert, SITE_POST_BOOT_CAP,
};
pub use site_domain::{
    byo_unverified_expires, site_domain_list, site_domain_put, site_domain_verify,
};
pub use site_domain_buy::{
    buy_quote_ok, domain_mail_after_verify, site_domain_buy, site_domain_check, site_domain_search,
};
pub use dns_verify::{cname_destination_matches, domain_cname_target};
pub use commerce_boot::{commerce_boot_build, order_progress_steps_json, site_published_meta_json};
pub use site_boot::{site_boot_get, site_boot_json_assemble};
pub use site_draft::{site_draft_get, site_draft_put};
pub use site_handle::{site_handle_normalize, site_handle_put};
pub use platform_site::{
    platform_home_assemble, platform_home_empty, platform_home_payload, platform_site_alien_id_is,
    platform_site_ensure, platform_site_handle_assign_check, platform_site_identity_put_check,
    PlatformHomeContact, PlatformHomeLink, PlatformHomePost, PLATFORM_HOME_POST_CAP,
    PLATFORM_SITE_ALIEN_ID, PLATFORM_SITE_OWNER_IID,
};
pub use grant::site_granted_iids;
pub use site_grant::{
    site_grant_delete, site_grant_delete_rpc, site_grant_list, site_grant_list_ensure_owner,
    site_grant_put, site_grant_put_rpc, site_grant_role_staff_manage, site_grant_role_writable,
    site_grantee_resolve, site_transfer_ownership, site_transfer_ownership_rpc,
};
pub use site_hr::{
    site_member_face_del, site_member_face_list, site_member_face_put, site_member_hr_cleanup,
    site_member_shift_ids_normalize, site_member_shift_sync, site_presence_location_list,
    site_presence_location_put, site_work_shift_list, site_work_shift_put,
};
pub use site_list::site_list;
pub use site_object::{site_object_list, site_object_put, site_object_upsert};
pub use site_preview::{site_draft_html_render, site_preview_token, site_preview_token_issue, site_preview_token_verify};
pub use query::{
    site_query_run, stock_report_from_query, stock_report_preview, stock_report_query_id,
    tx_browse_from_query, tx_browse_preview, tx_browse_query_id, tx_browse_title, StockReport,
    TxBrowseDisplayRow, TxBrowseReport, TxBrowseStats, STOCK_EXPORT_CAP, STOCK_PREVIEW_ROWS,
    TX_EXPORT_CAP, TX_PREVIEW_ROWS,
};
pub use site_product::{
    site_product_delete, site_product_list, site_product_put, site_product_reorder,
};
pub use product_icon::{
    product_icon_ensure, product_icon_id, product_icon_ids, product_icon_kind_from_rules,
    product_icon_kinds, product_icon_lookup, product_icon_name_key, ProductIconKind,
};
pub use product_icon_svg::product_icon_svg;
pub use site_queue::{
    guest_queue_get, guest_queue_get_json, guest_queue_take, guest_queue_take_json,
    site_queue_advance_serving, site_queue_list, site_queue_put,
};
pub use site_publish::{
    site_publish, site_publish_from_draft, site_published, SitePublishFromDraftResult,
};
pub use guest_product::{
    guest_product_list, guest_product_list_to_proto, product_cursor_decode, product_cursor_encode,
    product_grid_page_size, product_row_json, product_rows_for_grid, GuestProductListResult,
    ProductRow,
};
pub use guest_reservation::{
    availability_ok, guest_reservation_availability, reservation_windows_overlap, units_left,
    Availability, FreeObject,
};
pub use guest_design::{featured_contacts_load, FeaturedContact, GuestDesign};
pub use render::{
    block_html_render, guest_client_script_markup, guest_shell_html, product_card_html,
    ProductGridCtx,
};
pub use sync::sync_pull;
pub use sync_push::site_sync_push;
