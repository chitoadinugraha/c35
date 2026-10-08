#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum CatalogWebPhase {
    #[default]
    Off,
    Stock,
    PriceLookup,
    PriceCompare,
}

pub fn catalog_web_phase(matched_ids: &[String], has_site: bool) -> CatalogWebPhase {
    let has = |id: &str| matched_ids.iter().any(|m| m == id);
    if has("inst.site.catalog.add.menu") || has("inst.site.catalog.write") {
        CatalogWebPhase::Off
    } else if !has_site {
        CatalogWebPhase::Off
    } else if has("inst.site.price_compare") {
        CatalogWebPhase::PriceCompare
    } else if has("inst.site.catalog.price") {
        CatalogWebPhase::PriceLookup
    } else if has("inst.site.catalog.stock") {
        CatalogWebPhase::Stock
    } else {
        CatalogWebPhase::Off
    }
}

pub fn catalog_web_after_stock(phase: CatalogWebPhase, row_count: usize) -> bool {
    phase == CatalogWebPhase::PriceCompare
        || (phase == CatalogWebPhase::PriceLookup && row_count == 0)
}

/// Which catalog reads arm the post-query web phase.
/// Price compare must search after a full menu read (`product.list`) as well as `product.stock`.
/// Lookup and stock only arm on `product.stock`, so a menu list does not trigger a search.
pub fn catalog_query_arms_web(phase: CatalogWebPhase, query_id: &str) -> bool {
    match phase {
        CatalogWebPhase::PriceCompare => matches!(query_id, "product.stock" | "product.list"),
        CatalogWebPhase::PriceLookup | CatalogWebPhase::Stock => query_id == "product.stock",
        CatalogWebPhase::Off => false,
    }
}

pub fn catalog_skip_web_prefetch(matched_ids: &[String], phase: CatalogWebPhase) -> bool {
    phase != CatalogWebPhase::Off
        || matched_ids.iter().any(|id| {
            id == "inst.site.catalog.write"
                || id == "inst.site.catalog.add.menu"
                || id == "inst.site.builder"
                || id == "inst.device.facts"
                || id.starts_with("inst.mention.device_")
                || id == "inst.browser.topic"
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_web_no_site_stays_off() {
        let ids = vec!["inst.site.catalog.price".into(), "inst.web_search".into()];
        assert_eq!(catalog_web_phase(&ids, false), CatalogWebPhase::Off);
    }

    #[test]
    fn catalog_web_price_lookup_when_site() {
        let ids = vec!["inst.site.catalog.price".into(), "inst.web_search".into()];
        assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::PriceLookup);
        assert!(!catalog_web_after_stock(CatalogWebPhase::PriceLookup, 1));
        assert!(catalog_web_after_stock(CatalogWebPhase::PriceLookup, 0));
    }

    #[test]
    fn catalog_web_compare_beats_lookup() {
        let ids = vec![
            "inst.site.catalog.price".into(),
            "inst.site.price_compare".into(),
        ];
        assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::PriceCompare);
        assert!(catalog_web_after_stock(CatalogWebPhase::PriceCompare, 2));
    }

    #[test]
    fn catalog_compare_arms_on_menu_list() {
        assert!(catalog_query_arms_web(
            CatalogWebPhase::PriceCompare,
            "product.list"
        ));
        assert!(catalog_query_arms_web(
            CatalogWebPhase::PriceCompare,
            "product.stock"
        ));
        assert!(!catalog_query_arms_web(
            CatalogWebPhase::PriceLookup,
            "product.list"
        ));
        assert!(catalog_query_arms_web(
            CatalogWebPhase::PriceLookup,
            "product.stock"
        ));
        assert!(!catalog_query_arms_web(
            CatalogWebPhase::Off,
            "product.list"
        ));
    }

    #[test]
    fn catalog_web_stock_never_searches() {
        assert!(!catalog_web_after_stock(CatalogWebPhase::Stock, 0));
    }

    #[test]
    fn catalog_web_write_skips_prefetch() {
        let ids = vec![
            "inst.site.catalog.write".into(),
            "inst.site.catalog.price".into(),
            "inst.web_search".into(),
        ];
        assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::Off);
        assert!(catalog_skip_web_prefetch(&ids, CatalogWebPhase::Off));
    }

    #[test]
    fn catalog_web_menu_add_skips_prefetch() {
        let ids = vec![
            "inst.site.catalog.add.menu".into(),
            "inst.site.catalog.price".into(),
            "inst.web_search".into(),
        ];
        assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::Off);
        assert!(catalog_skip_web_prefetch(&ids, CatalogWebPhase::Off));
    }

    #[test]
    fn catalog_web_site_builder_skips_prefetch() {
        let ids = vec!["inst.site.builder".into(), "inst.web_search".into()];
        assert!(catalog_skip_web_prefetch(&ids, CatalogWebPhase::Off));
    }
}
