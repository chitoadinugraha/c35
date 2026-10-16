use serde_json::{json, Value};

/// Guest-facing copy keyed off `SiteDoc.meta.lang` / `meta.locale` (default Indonesian).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct GuestI18n {
    pub indonesian: bool,
}

impl GuestI18n {
    pub fn from_meta(meta: &Value) -> Self {
        let raw = meta
            .get("lang")
            .or_else(|| meta.get("locale"))
            .and_then(|v| v.as_str())
            .map(|s| s.trim().to_ascii_lowercase())
            .unwrap_or_default();
        let indonesian = if raw.is_empty() {
            true
        } else {
            raw.starts_with("id")
        };
        Self { indonesian }
    }

    pub fn english() -> Self {
        Self { indonesian: false }
    }

    pub fn html_lang(&self) -> &'static str {
        if self.indonesian {
            "id"
        } else {
            "en"
        }
    }

    pub fn price_contact(&self) -> &'static str {
        if self.indonesian {
            "Hubungi kami"
        } else {
            "Contact us"
        }
    }

    pub fn tile_contact_cta(&self) -> &'static str {
        if self.indonesian {
            "Hubungi"
        } else {
            "Contact"
        }
    }

    pub fn catalog_default_title(&self) -> &'static str {
        if self.indonesian {
            "Katalog & Layanan"
        } else {
            "Catalog & services"
        }
    }

    pub fn catalog_section_eyebrow(&self) -> &'static str {
        if self.indonesian {
            "Katalog"
        } else {
            "Catalog"
        }
    }

    pub fn catalog_search_placeholder(&self) -> &'static str {
        if self.indonesian {
            "Cari produk…"
        } else {
            "Search products…"
        }
    }

    pub fn hub_tab_shop(&self) -> &'static str {
        if self.indonesian {
            "Toko"
        } else {
            "Shop"
        }
    }

    pub fn hub_tab_posts(&self) -> &'static str {
        if self.indonesian {
            "Posting"
        } else {
            "Posts"
        }
    }

    pub fn filter_all(&self) -> &'static str {
        if self.indonesian {
            "Semua"
        } else {
            "All"
        }
    }

    pub fn sign_in(&self) -> &'static str {
        if self.indonesian {
            "Masuk"
        } else {
            "Sign in"
        }
    }

    pub fn share_store_aria(&self) -> &'static str {
        if self.indonesian {
            "Bagikan toko"
        } else {
            "Share store"
        }
    }

    pub fn load_more(&self) -> &'static str {
        if self.indonesian {
            "Muat lebih banyak"
        } else {
            "Load more"
        }
    }

    pub fn loading(&self) -> &'static str {
        if self.indonesian {
            "Memuat…"
        } else {
            "Loading…"
        }
    }

    pub fn detail_aria(&self) -> &'static str {
        if self.indonesian {
            "Detail produk"
        } else {
            "Product details"
        }
    }

    pub fn share_aria(&self) -> &'static str {
        if self.indonesian {
            "Bagikan produk"
        } else {
            "Share product"
        }
    }

    pub fn assistant_chat_subtitle(&self) -> &'static str {
        if self.indonesian {
            "Biasanya membalas dalam beberapa menit"
        } else {
            "We typically reply in a few minutes"
        }
    }

    /// `{name}` is replaced with the site or chat title in guest JS.
    pub fn assistant_chat_empty(&self) -> &'static str {
        if self.indonesian {
            "Tanyakan ke {name} tentang produk, jam buka, atau pesanan Anda."
        } else {
            "Ask {name} about products, hours, or your order."
        }
    }

    pub fn assistant_send_aria(&self) -> &'static str {
        if self.indonesian {
            "Kirim pesan"
        } else {
            "Send message"
        }
    }

    pub fn assistant_close_aria(&self) -> &'static str {
        if self.indonesian {
            "Tutup"
        } else {
            "Close"
        }
    }

    pub fn assistant_powered_prefix(&self) -> &'static str {
        "Powered by"
    }

    pub fn assistant_placeholder_default(&self) -> &'static str {
        if self.indonesian {
            "Ketik pesan…"
        } else {
            "Type a message…"
        }
    }

    pub fn to_json(&self) -> Value {
        json!({
            "lang": self.html_lang(),
            "price_contact": self.price_contact(),
            "tile_contact_cta": self.tile_contact_cta(),
            "filter_all": self.filter_all(),
            "sign_in": self.sign_in(),
            "share_store_aria": self.share_store_aria(),
            "load_more": self.load_more(),
            "loading": self.loading(),
            "detail_aria": self.detail_aria(),
            "share_aria": self.share_aria(),
            "assistant_chat_subtitle": self.assistant_chat_subtitle(),
            "assistant_chat_empty": self.assistant_chat_empty(),
            "assistant_send_aria": self.assistant_send_aria(),
            "assistant_close_aria": self.assistant_close_aria(),
            "assistant_powered_prefix": self.assistant_powered_prefix(),
            "assistant_placeholder_default": self.assistant_placeholder_default(),
        })
    }
}

/// `hub` (narrow link-in-bio) or `store` (wider catalog). Default `hub`; `store` only when set in meta.
pub fn guest_layout_mode(meta: &Value, _product_count: usize) -> &'static str {
    if let Some(v) = meta
        .get("guest_layout")
        .or_else(|| meta.get("layout_mode"))
        .and_then(|x| x.as_str())
    {
        let t = v.trim().to_ascii_lowercase();
        if t == "store" {
            return "store";
        }
        if t == "hub" {
            return "hub";
        }
    }
    "hub"
}

pub fn guest_layout_page_max_css(layout: &str) -> &'static str {
    if layout == "store" {
        "min(1040px, 100%)"
    } else {
        "600px"
    }
}

pub fn guest_layout_grid_min_css(layout: &str) -> &'static str {
    if layout == "store" {
        "200px"
    } else {
        "168px"
    }
}
