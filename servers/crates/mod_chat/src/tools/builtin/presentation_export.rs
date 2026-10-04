use anyhow::{bail, Context, Result};
use serde_json::json;
use std::path::Path;
use crate::pdf_cas::{pdf_extract_for_hash, pdf_structure_for_hash, PDF_EXTRACT_DEFAULT_MAX_CHARS as EXTRACT_DEFAULT_MAX};
use c35_mod_youtube::{video_extract_json, video_structure_json, EXTRACT_DEFAULT_MAX_CHARS as VIDEO_EXTRACT_DEFAULT};
use crate::tool;

fn cas_secret_from_env() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

fn resolve_presentation_runner() -> Result<(String, Vec<String>)> {
    // 1. Direct binary env var
    if let Ok(bin) = std::env::var("PPTX_RENDER_BIN") {
        if Path::new(&bin).exists() {
            return Ok((bin, vec![]));
        }
    }

    // 2. Direct script env var (using bun)
    if let Ok(script) = std::env::var("PPTX_RENDER_SCRIPT") {
        if Path::new(&script).exists() {
            return Ok(("bun".to_string(), vec!["run".to_string(), script]));
        }
    }

    // 3. Search common locations for compiled binary
    let bin_candidates = [
        "/app/render_pptx",
        "./render_pptx",
        "./scripts/presentation/render_pptx",
        "./scripts/presentation/render_pptx.exe",
        "../scripts/presentation/render_pptx.exe",
        "../../scripts/presentation/render_pptx.exe",
    ];

    for candidate in bin_candidates {
        if Path::new(candidate).exists() {
            return Ok((candidate.to_string(), vec![]));
        }
    }

    // 4. Script candidates using bun
    let script_candidates = [
        "/app/scripts/presentation/render_pptx.ts",
        "scripts/presentation/render_pptx.ts",
        "./scripts/presentation/render_pptx.ts",
        "../scripts/presentation/render_pptx.ts",
        "../../scripts/presentation/render_pptx.ts",
    ];

    for candidate in script_candidates {
        if Path::new(candidate).exists() {
            return Ok(("bun".to_string(), vec!["run".to_string(), candidate.to_string()]));
        }
    }

    // Fallback: assume bun is in PATH and default relative script path
    Ok(("bun".to_string(), vec!["run".to_string(), "scripts/presentation/render_pptx.ts".to_string()]))
}

pub async fn presentation_export_exec(
    pool: &sqlx::PgPool,
    slides_markdown: &str,
    title: &str,
    theme: &str,
) -> Result<serde_json::Value> {
    let slides_markdown = slides_markdown.trim();
    if slides_markdown.is_empty() {
        bail!("slides_markdown cannot be empty");
    }

    let (program, args) = resolve_presentation_runner()?;

    let resolved = crate::presentation_theme_resolve(pool, theme).await;
    let input_payload = json!({
        "title": if title.trim().is_empty() { "Presentation" } else { title.trim() },
        "theme": resolved.id,
        "theme_tokens": resolved.tokens,
        "slides_markdown": slides_markdown,
    });
    let input_bytes = serde_json::to_vec(&input_payload)?;

    let mut cmd = tokio::process::Command::new(&program);
    cmd.args(&args)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped());

    let mut child = cmd
        .spawn()
        .with_context(|| format!("failed to spawn presentation generator '{program}'"))?;

    if let Some(mut stdin) = child.stdin.take() {
        use tokio::io::AsyncWriteExt;
        stdin
            .write_all(&input_bytes)
            .await
            .context("failed to write input to presentation runner")?;
    }

    let output = child
        .wait_with_output()
        .await
        .context("presentation generator process failed")?;

    if !output.status.success() {
        let err_msg = String::from_utf8_lossy(&output.stderr);
        bail!("Presentation rendering failed (exit {}): {}", output.status, err_msg.trim());
    }

    let pptx_bytes = output.stdout;
    if pptx_bytes.is_empty() {
        bail!("Presentation generator returned empty output");
    }

    let secret = cas_secret_from_env();
    let mime = "application/vnd.openxmlformats-officedocument.presentationml.presentation";
    let put = c35_mod_file::cas_put(
        pool,
        &c35_mod_file::cas_dir_default(),
        &secret,
        &pptx_bytes,
        mime,
    )
    .await
    .context("failed to store generated presentation into CAS")?;

    let clean_title = title.trim();
    let safe_title = if clean_title.is_empty() {
        "presentation"
    } else {
        clean_title
    }
    .chars()
    .map(|c| if c.is_alphanumeric() || c == '-' || c == '_' { c } else { '_' })
    .collect::<String>();

    let filename = format!("{safe_title}.pptx");
    let download_url = format!("{}/{}", put.url.trim_end_matches('/'), filename);

    Ok(json!({
        "ok": true,
        "runner": "cluster",
        "tool": "presentation.export",
        "file_hash": put.hash,
        "download_url": download_url,
        "filename": filename,
        "mime": put.mime_type,
        "title": if clean_title.is_empty() { "Presentation" } else { clean_title },
        "size_bytes": put.size_bytes,
        "block": {
            "kind": "file",
            "collapsed": false,
            "body": {
                "hash": put.hash,
                "url": download_url,
                "mime": put.mime_type,
                "name": filename,
                "size": put.size_bytes,
            }
        }
    }))
}

tool! {
    struct: PresentationExportTool,
    name: "presentation.export",
    aliases: ["presentation_export", "pptx.export", "pptx_export"],
    description: "Export and compile a markdown/marp slide deck into an editable, professional PowerPoint (.pptx) file. Generates formatted slides with 16:9 widescreen layout, cards, metrics, tables, and speaker notes.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["export pptx", "download presentation", "save slides as powerpoint", "export slide deck", "download ppt", "generate presentation file"],
    ui_calling_key: "tool.presentation.export.calling",
    ui_done_key: "tool.presentation.export.done",
    parameters: {
        slides_markdown: (string, "Markdown or Marp formatted text representing the complete slide deck, where each slide is separated by '---'.", required),
        title: (string, "Presentation title used on the title slide and for the file download name.", optional, default = "Presentation"),
        theme: (string, "Visual theme: 'dark' (default Alien AI dark neon), 'light' (clean white/slate), or 'corporate' (navy/emerald).", optional, default = "dark"),
    },
    execute: |args, ctx| {
        let slides_markdown = args["slides_markdown"].as_str().unwrap_or_default();
        let title = args["title"].as_str().unwrap_or("Presentation");
        let theme = args["theme"].as_str().unwrap_or("dark");
        presentation_export_exec(&ctx.pool, slides_markdown, title, theme).await
    }
}

tool! {
    struct: PresentationSourceStructureTool,
    name: "presentation.source.structure",
    aliases: ["pdf.structure"],
    description: "PDF TOC and page count from file_hash (no full text).",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["pdf outline", "table of contents"],
    ui_calling_key: "tool.presentation.source.structure.calling",
    ui_done_key: "tool.presentation.source.structure.done",
    parameters: {
        file_hash: (string, "CAS hash", required),
        file_name: (string, "filename", optional, default = ""),
    },
    execute: |args, ctx| {
        let hash = args["file_hash"].as_str().unwrap_or_default().trim();
        if hash.is_empty() {
            bail!("file_hash required");
        }
        let name = args["file_name"].as_str().unwrap_or("");
        Ok(pdf_structure_for_hash(&ctx.pool, hash, name).await?)
    }
}

tool! {
    struct: PresentationSourceExtractTool,
    name: "presentation.source.extract",
    aliases: ["pdf.extract"],
    description: "PDF text for page range after user chose scope.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["extract pdf pages"],
    ui_calling_key: "tool.presentation.source.extract.calling",
    ui_done_key: "tool.presentation.source.extract.done",
    parameters: {
        file_hash: (string, "CAS hash", required),
        page_from: (integer, "first page", required),
        page_to: (integer, "last page", required),
        max_chars: (integer, "max chars", optional, default = 14000),
    },
    execute: |args, ctx| {
        let hash = args["file_hash"].as_str().unwrap_or_default().trim();
        if hash.is_empty() {
            bail!("file_hash required");
        }
        let page_from = args["page_from"].as_u64().unwrap_or(1) as u32;
        let page_to = args["page_to"].as_u64().unwrap_or(page_from as u64) as u32;
        let max_chars = args["max_chars"].as_u64().unwrap_or(EXTRACT_DEFAULT_MAX as u64) as usize;
        Ok(pdf_extract_for_hash(&ctx.pool, hash, page_from, page_to, max_chars).await?)
    }
}

tool! {
    struct: PresentationVideoStructureTool,
    name: "presentation.source.video_structure",
    aliases: ["youtube.structure", "video.structure"],
    description: "YouTube chapters and metadata (no full transcript). Uses yt-dlp via CF proxy.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["youtube chapters", "video outline"],
    ui_calling_key: "tool.presentation.source.video_structure.calling",
    ui_done_key: "tool.presentation.source.video_structure.done",
    parameters: {
        url: (string, "YouTube URL or 11-char video_id", required),
    },
    execute: |args, ctx| {
        let url = args["url"].as_str().unwrap_or_default().trim();
        if url.is_empty() {
            bail!("url required");
        }
        Ok(video_structure_json(&ctx.pool, url, ctx.owner_iid).await?)
    }
}

tool! {
    struct: PresentationVideoExtractTool,
    name: "presentation.source.video_extract",
    aliases: ["youtube.extract", "video.extract"],
    description: "Caption text for a YouTube time range (seconds). Call after user picks scope.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["youtube transcript section", "video clip text"],
    ui_calling_key: "tool.presentation.source.video_extract.calling",
    ui_done_key: "tool.presentation.source.video_extract.done",
    parameters: {
        video_id: (string, "11-char video id", required),
        start_sec: (number, "range start seconds", required),
        end_sec: (number, "range end seconds", required),
        max_chars: (integer, "max chars", optional, default = 14000),
    },
    execute: |args, ctx| {
        let video_id = args["video_id"].as_str().unwrap_or_default().trim();
        if video_id.is_empty() {
            bail!("video_id required");
        }
        let start_sec = args["start_sec"].as_f64().unwrap_or(0.0);
        let end_sec = args["end_sec"].as_f64().unwrap_or(start_sec);
        let max_chars = args["max_chars"].as_u64().unwrap_or(VIDEO_EXTRACT_DEFAULT as u64) as usize;
        Ok(video_extract_json(&ctx.pool, video_id, start_sec, end_sec, max_chars, ctx.owner_iid).await?)
    }
}

tool! {
    struct: PresentationCreateTool,
    name: "presentation.create",
    aliases: ["presentation_create", "slide.create", "slides.create", "presentation.deck"],
    description: "Create and present a visual, interactive slide deck. Renders a native presentation card directly in the chat with pagination, slide count, and fullscreen presentation view.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["create presentation", "generate slides", "make slide deck", "bikin slide", "buat presentasi", "slide deck"],
    ui_calling_key: "tool.presentation.create.calling",
    ui_done_key: "tool.presentation.create.done",
    parameters: {
        title: (string, "Presentation title", required),
        slides_markdown: (string, "Slide markdown text where each slide is separated by '---'. Each slide starts with a bold heading '# Slide Title' and bullet points.", optional, default = ""),
        theme: (string, "Visual theme: 'dark' (default Alien AI dark neon), 'light', or 'corporate'", optional, default = "dark"),
    },
    execute: |args, _ctx| {
        let title = args["title"].as_str().unwrap_or("Presentation").trim();
        let clean_title = if title.is_empty() { "Presentation" } else { title };
        let theme = args["theme"].as_str().unwrap_or("dark").trim();

        let mut slides: Vec<String> = Vec::new();
        if let Some(arr) = args["slides"].as_array() {
            for item in arr {
                if let Some(s) = item.as_str() {
                    let st = s.trim();
                    if !st.is_empty() {
                        slides.push(st.to_string());
                    }
                }
            }
        }
        if slides.is_empty() {
            if let Some(md) = args["slides_markdown"].as_str() {
                for s in md.split("\n---") {
                    let st = s.trim().trim_start_matches("---").trim();
                    if !st.is_empty() {
                        slides.push(st.to_string());
                    }
                }
            }
        }
        if slides.is_empty() {
            slides.push(format!("# {clean_title}\n- Overview"));
        }

        let now_ms = chrono::Utc::now().timestamp_millis();
        let slide_count = slides.len();

        Ok(json!({
            "ok": true,
            "tool": "presentation.create",
            "title": clean_title,
            "slide_count": slide_count,
            "block": {
                "kind": "presentation.deck",
                "collapsed": false,
                "body": {
                    "title": clean_title,
                    "slides": slides,
                    "created_at_ms": now_ms,
                    "theme": theme,
                }
            }
        }))
    }
}

tool! {
    struct: PresentationPatchTool,
    name: "presentation.patch",
    aliases: ["presentation_patch", "slide.patch", "slides.patch"],
    description: "Apply a targeted edit or patch to an existing slide deck (replace, insert, or delete a slide) without regenerating the entire presentation.",
    topics: ["presentation"],
    always: ["presentation"],
    rag_phrases: ["edit slide", "update slide", "patch slide", "tambah slide", "hapus slide", "ubah slide", "ganti slide"],
    ui_calling_key: "tool.presentation.patch.calling",
    ui_done_key: "tool.presentation.patch.done",
    parameters: {
        slide_index: (integer, "1-indexed slide number to modify or delete, or after which to insert", required),
        action: (string, "Patch action: 'replace' (default), 'insert', or 'delete'", optional, default = "replace"),
        content: (string, "Markdown content for the replaced or inserted slide (not needed for delete)", optional, default = ""),
        title: (string, "Optional presentation title", optional, default = "Presentation"),
    },
    execute: |args, _ctx| {
        let slide_index = args["slide_index"].as_u64().unwrap_or(1) as usize;
        let action = args["action"].as_str().unwrap_or("replace").trim().to_ascii_lowercase();
        let content = args["content"].as_str().unwrap_or("").trim();
        let title = args["title"].as_str().unwrap_or("Presentation").trim();

        let patch_comment = match action.as_str() {
            "delete" => format!("<!-- slide-patch:delete {slide_index} -->"),
            "insert" | "add" => format!("<!-- slide-patch:add after={slide_index} -->\n{content}"),
            _ => format!("<!-- slide-patch:{slide_index} -->\n{content}"),
        };

        let eyebrow = match action.as_str() {
            "delete" => format!("SLIDE {slide_index} DELETED"),
            "insert" | "add" => format!("SLIDE ADDED AFTER {slide_index}"),
            _ => format!("SLIDE {slide_index} UPDATED"),
        };

        let now_ms = chrono::Utc::now().timestamp_millis();

        Ok(json!({
            "ok": true,
            "tool": "presentation.patch",
            "slide_index": slide_index,
            "action": action,
            "patch": patch_comment,
            "block": {
                "kind": "presentation.deck",
                "collapsed": false,
                "body": {
                    "title": if title.is_empty() || title == "Presentation" { format!("Slide {slide_index} Updated") } else { title.to_string() },
                    "content": patch_comment,
                    "created_at_ms": now_ms,
                    "eyebrow": eyebrow,
                }
            }
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tools::Tool;

    #[test]
    fn test_presentation_export_definition() {
        let tool = PresentationExportTool;
        let def = tool.definition();
        assert_eq!(def.name, "presentation.export");
        assert!(def.aliases.contains(&"pptx.export".to_string()));
        assert!(def.topics.contains(&"presentation".to_string()));
        assert_eq!(def.parameters["properties"]["slides_markdown"]["type"], "string");
        assert_eq!(def.parameters["properties"]["theme"]["default"], "dark");
    }

    #[test]
    fn test_resolve_presentation_runner() {
        let res = resolve_presentation_runner();
        assert!(res.is_ok());
        let (cmd, _args) = res.unwrap();
        assert!(!cmd.is_empty());
    }

    #[tokio::test]
    async fn test_presentation_create_execution() {
        let tool = PresentationCreateTool;
        let def = tool.definition();
        assert_eq!(def.name, "presentation.create");
        assert!(def.always.contains(&"presentation".to_string()));

        let ctx = crate::tools::ToolContext::new(
            sqlx::PgPool::connect_lazy("postgres://localhost/test").unwrap(),
            None,
            1,
            1,
            None,
            crate::mention_context::MentionContext::default(),
            vec![],
            "",
            "en-US",
            "",
            "",
            "",
            "",
            "req1",
            reqwest::Client::new(),
        );
        let res = tool
            .execute(
                json!({
                    "title": "Cooking Guide",
                    "slides_markdown": "# Step 1: Boil Water\n- 400ml\n---\n# Step 2: Add Noodles\n- 3 mins"
                }),
                &ctx,
            )
            .await
            .unwrap();

        assert_eq!(res["ok"], true);
        assert_eq!(res["slide_count"], 2);
        assert_eq!(res["block"]["kind"], "presentation.deck");
        assert_eq!(res["block"]["body"]["title"], "Cooking Guide");
    }

    #[tokio::test]
    async fn test_presentation_patch_execution() {
        let tool = PresentationPatchTool;
        let def = tool.definition();
        assert_eq!(def.name, "presentation.patch");
        assert!(def.always.contains(&"presentation".to_string()));

        let ctx = crate::tools::ToolContext::new(
            sqlx::PgPool::connect_lazy("postgres://localhost/test").unwrap(),
            None,
            1,
            1,
            None,
            crate::mention_context::MentionContext::default(),
            vec![],
            "",
            "en-US",
            "",
            "",
            "",
            "",
            "req1",
            reqwest::Client::new(),
        );
        let res = tool
            .execute(
                json!({
                    "slide_index": 2,
                    "action": "replace",
                    "content": "# Updated Step 2\n- 4 minutes"
                }),
                &ctx,
            )
            .await
            .unwrap();

        assert_eq!(res["ok"], true);
        assert_eq!(res["slide_index"], 2);
        assert_eq!(res["block"]["kind"], "presentation.deck");
        assert!(res["patch"].as_str().unwrap().contains("slide-patch:2"));
    }
}

