//! Document index (PDF today; docx/pptx later). Image bytes stay off the JSON blob.

use serde::{Deserialize, Deserializer, Serialize, Serializer};

use crate::pdf::PdfSection;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DocPage {
    pub n: u32,
    pub text: String,
    pub needs_ocr: bool,
    /// In-memory only. Never serialize into the JSON blob.
    #[serde(skip)]
    pub image_jpeg: Option<Vec<u8>>,
}

#[derive(Debug, Clone)]
pub struct DocIndex {
    pub kind: String,
    pub name: String,
    pub units: u32,
    pub outline: Vec<PdfSection>,
    pub pages: Vec<DocPage>,
}

pub fn doc_index_json(index: &DocIndex) -> serde_json::Value {
    serde_json::json!({
        "kind": index.kind,
        "name": index.name,
        "units": index.units,
        "outline": index.outline.iter().map(|s| {
            serde_json::json!({
                "title": s.title,
                "unit": s.page,
                "level": s.level,
            })
        }).collect::<Vec<_>>(),
        "pages": index.pages.iter().map(|p| {
            serde_json::json!({
                "n": p.n,
                "text": p.text,
                "chars": p.text.chars().count(),
                "needs_ocr": p.needs_ocr,
            })
        }).collect::<Vec<_>>(),
    })
}

impl Serialize for DocIndex {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        doc_index_json(self).serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for DocIndex {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        struct Wire {
            kind: String,
            name: String,
            units: u32,
            #[serde(default)]
            outline: Vec<OutlineWire>,
            #[serde(default)]
            pages: Vec<PageWire>,
        }
        #[derive(Deserialize)]
        struct OutlineWire {
            title: String,
            #[serde(alias = "page")]
            unit: u32,
            level: u8,
        }
        #[derive(Deserialize)]
        struct PageWire {
            n: u32,
            #[serde(default)]
            text: String,
            #[serde(default)]
            needs_ocr: bool,
        }
        let wire = Wire::deserialize(deserializer)?;
        Ok(DocIndex {
            kind: wire.kind,
            name: wire.name,
            units: wire.units,
            outline: wire
                .outline
                .into_iter()
                .map(|o| PdfSection {
                    title: o.title,
                    page: o.unit,
                    level: o.level,
                })
                .collect(),
            pages: wire
                .pages
                .into_iter()
                .map(|p| DocPage {
                    n: p.n,
                    text: p.text,
                    needs_ocr: p.needs_ocr,
                    image_jpeg: None,
                })
                .collect(),
        })
    }
}
