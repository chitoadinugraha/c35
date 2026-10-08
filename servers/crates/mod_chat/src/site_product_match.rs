/// A catalog row that matched a product name or sku inside the site scope.
pub struct ProductHit {
    pub site_iid: i64,
    pub product_id: i64,
    pub name: String,
    pub price: i64,
}

/// Unique-or-ambiguous result of a cross-site product lookup.
pub enum ProductMatch {
    None,
    One(ProductHit),
    Many(Vec<ProductHit>),
}

/// `One` only when there is exactly one hit. Two rows, even on one site, are `Many`.
pub fn product_match_classify(mut hits: Vec<ProductHit>) -> ProductMatch {
    match hits.len() {
        0 => ProductMatch::None,
        1 => ProductMatch::One(hits.pop().expect("len 1")),
        _ => ProductMatch::Many(hits),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn product_match_one_site_one_row() {
        let hit = ProductHit {
            site_iid: 1,
            product_id: 9,
            name: "A".into(),
            price: 10000,
        };
        assert!(matches!(
            product_match_classify(vec![hit]),
            ProductMatch::One(_)
        ));
    }

    #[test]
    fn product_match_two_sites_is_many() {
        let hits = vec![
            ProductHit {
                site_iid: 1,
                product_id: 9,
                name: "A".into(),
                price: 10000,
            },
            ProductHit {
                site_iid: 2,
                product_id: 8,
                name: "A".into(),
                price: 12000,
            },
        ];
        assert!(matches!(
            product_match_classify(hits),
            ProductMatch::Many(_)
        ));
    }

    #[test]
    fn product_match_two_rows_one_site_is_many() {
        let hits = vec![
            ProductHit {
                site_iid: 1,
                product_id: 9,
                name: "A".into(),
                price: 10000,
            },
            ProductHit {
                site_iid: 1,
                product_id: 10,
                name: "A besar".into(),
                price: 11000,
            },
        ];
        assert!(matches!(
            product_match_classify(hits),
            ProductMatch::Many(_)
        ));
    }
}
