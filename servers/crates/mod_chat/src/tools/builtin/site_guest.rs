use anyhow::anyhow;

use crate::site_guest_cart::{guest_cart_get_exec, guest_cart_patch_exec};
use crate::tool;

tool! {
    struct: SiteGuestCartGetTool,
    name: "site.guest.cart.get",
    aliases: ["site_guest_cart_get"],
    description: "Read the visitor cart session for this published site (server-side).",
    topics: ["site.guest"],
    always: ["site.guest"],
    ui_calling_key: "tool.site.guest.cart.get.calling",
    ui_done_key: "tool.site.guest.cart.get.done",
    readonly: true,
    parameters: {},
    execute: |_args, ctx| {
        let site_iid = ctx.site_iid.unwrap_or(0);
        let visitor = ctx.guest_visitor_id.as_deref().unwrap_or("");
        guest_cart_get_exec(site_iid, visitor)
            .await
            .map_err(|e| anyhow!(e))
    }
}

tool! {
    struct: SiteGuestCartPatchTool,
    name: "site.guest.cart.patch",
    aliases: ["site_guest_cart_patch"],
    description: "Update the visitor cart session (lines with product_id, name, price, qty, optional note per line). Use merge=true to append lines.",
    topics: ["site.guest"],
    always: ["site.guest"],
    ui_calling_key: "tool.site.guest.cart.patch.calling",
    ui_done_key: "tool.site.guest.cart.patch.done",
    parameters: {
        lines: (array, "Cart line objects", optional),
        merge: (boolean, "Append to existing cart instead of replacing", optional, default = false),
    },
    execute: |args, ctx| {
        let site_iid = ctx.site_iid.unwrap_or(0);
        let visitor = ctx.guest_visitor_id.as_deref().unwrap_or("");
        guest_cart_patch_exec(site_iid, visitor, &args)
            .await
            .map_err(|e| anyhow!(e))
    }
}