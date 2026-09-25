import pptxgen from "pptxgenjs";

interface PresentationInput {
  title?: string;
  theme?: "dark" | "light" | "corporate";
  prompt?: string;
  slides_markdown: string;
}

interface ThemeConfig {
  bg: string;
  cardBg: string;
  text: string;
  subtext: string;
  accent: string;
  accent2: string;
  border: string;
}

const THEMES: Record<string, ThemeConfig> = {
  dark: {
    bg: "0C0C0E",
    cardBg: "16161A",
    text: "F4F4F5",
    subtext: "A1A1AA",
    accent: "06B6D4", // Alien AI Cyan
    accent2: "3B82F6",
    border: "27272A",
  },
  light: {
    bg: "FFFFFF",
    cardBg: "F8FAFC",
    text: "0F172A",
    subtext: "64748B",
    accent: "2563EB", // Royal Blue
    accent2: "0284C7",
    border: "E2E8F0",
  },
  corporate: {
    bg: "0F172A",
    cardBg: "1E293B",
    text: "F8FAFC",
    subtext: "94A3B8",
    accent: "10B981", // Emerald
    accent2: "06B6D4",
    border: "334155",
  },
};

interface ParsedSlide {
  raw: string;
  title: string;
  subtitle: string;
  bullets: string[];
  tables: string[][][];
  metrics: { value: string; label: string }[];
  notes: string;
}

function parseMarkdownSlide(rawText: string): ParsedSlide {
  let content = rawText.trim();
  let notes = "";

  // 1. Extract speaker notes
  const htmlNoteMatch = content.match(/<!--\s*notes?:\s*([\s\S]*?)-->/i);
  if (htmlNoteMatch) {
    notes += (htmlNoteMatch[1] || "").trim() + "\n";
    content = content.replace(htmlNoteMatch[0], "").trim();
  }

  const alertNoteMatch = content.match(/>\s*\[!NOTE\]\s*([\s\S]*?)(?=\n\n|\n[#*-]|$)/i);
  if (alertNoteMatch) {
    notes += (alertNoteMatch[1] || "").trim() + "\n";
    content = content.replace(alertNoteMatch[0], "").trim();
  }

  const lines = content.split("\n").map((l) => l.trimEnd());
  let title = "";
  let subtitle = "";
  const bullets: string[] = [];
  const metrics: { value: string; label: string }[] = [];
  const tables: string[][][] = [];

  let currentTable: string[][] | null = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) {
      if (currentTable) {
        tables.push(currentTable);
        currentTable = null;
      }
      continue;
    }

    // Markdown Table row
    if (line.startsWith("|") && line.endsWith("|")) {
      const parts = line.split("|").slice(1, -1).map((c) => c.trim());
      // Skip delimiter row e.g. |---|---|
      if (parts.every((p) => p.match(/^:?-+:?$/))) {
        continue;
      }
      if (!currentTable) currentTable = [];
      currentTable.push(parts);
      continue;
    } else if (currentTable) {
      tables.push(currentTable);
      currentTable = null;
    }

    // Title header
    if (line.startsWith("# ") && !title) {
      title = line.replace(/^#\s+/, "").trim();
      continue;
    }

    // Subtitle / section header
    if (line.startsWith("## ") && !subtitle) {
      subtitle = line.replace(/^##\s+/, "").trim();
      continue;
    }

    // Metric pattern: > **+140%** Metric label or **$3.5M** Metric
    const metricMatch = line.match(/^(?:>\s*)?\*\*([+$€£¥\d.,%]+[KkMmBbTt]?)\*\*\s*[:\-–—]?\s*(.*)$/);
    if (metricMatch && metricMatch[1]) {
      metrics.push({
        value: metricMatch[1].trim(),
        label: (metricMatch[2] || "").trim(),
      });
      continue;
    }

    // Bullet points
    if (line.match(/^[-*•]\s+/) || line.match(/^\d+\.\s+/)) {
      const text = line.replace(/^[-*•\d.]+\s+/, "").trim();
      if (text) bullets.push(text);
      continue;
    }

    // Fallback regular line
    if (!title) {
      title = line;
    } else if (!subtitle && bullets.length === 0) {
      subtitle = line;
    } else {
      bullets.push(line);
    }
  }

  if (currentTable) {
    tables.push(currentTable);
  }

  return { raw: rawText, title, subtitle, bullets, tables, metrics, notes: notes.trim() };
}

export async function generatePresentation(input: PresentationInput): Promise<Uint8Array> {
  const pptx = new pptxgen();

  // 16:9 Widescreen standard
  pptx.layout = "LAYOUT_16x9";
  pptx.title = input.title || "Alien AI Presentation";
  pptx.author = "Alien AI";
  pptx.company = "Alien AI Platform";
  pptx.subject = input.title || "Generated Presentation";
  if (input.prompt) {
    pptx.comments = `Generated via Alien AI with prompt: ${input.prompt}`;
  }

  const theme = THEMES[input.theme || "dark"] || THEMES.dark;

  // Split markdown into individual slides
  const rawSlides = input.slides_markdown
    .split(/(?:^|\n)---\s*(?:\n|$)/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const slidesToRender = rawSlides.length > 0 ? rawSlides : [input.slides_markdown];
  const totalSlides = slidesToRender.length;

  for (let idx = 0; idx < totalSlides; idx++) {
    const parsed = parseMarkdownSlide(slidesToRender[idx]);
    const slide = pptx.addSlide();
    slide.bkgd = theme.bg;

    // Attach speaker notes
    if (parsed.notes) {
      slide.addNotes(parsed.notes);
    } else if (input.prompt && idx === 0) {
      slide.addNotes(`Original Prompt: ${input.prompt}`);
    }

    const isTitleSlide = idx === 0 && (parsed.bullets.length <= 1 && parsed.tables.length === 0);

    if (isTitleSlide) {
      // --- TITLE SLIDE LAYOUT ---
      // Subtle top accent bar
      slide.addShape(pptx.ShapeType.rect, {
        x: 0.8,
        y: 1.2,
        w: 1.2,
        h: 0.08,
        fill: { color: theme.accent },
        line: { color: theme.accent },
      });

      // Main title
      slide.addText(parsed.title || input.title || "Presentation", {
        x: 0.8,
        y: 1.6,
        w: 11.5,
        h: 2.2,
        fontSize: 40,
        fontFace: "Arial",
        bold: true,
        color: theme.text,
        valign: "middle",
      });

      // Subtitle
      if (parsed.subtitle || parsed.bullets[0]) {
        slide.addText(parsed.subtitle || parsed.bullets[0], {
          x: 0.8,
          y: 4.0,
          w: 11.0,
          h: 1.2,
          fontSize: 20,
          fontFace: "Calibri",
          color: theme.subtext,
          valign: "top",
        });
      }

      // Branding watermark bottom left
      slide.addText("Alien AI Platform", {
        x: 0.8,
        y: 6.5,
        w: 5.0,
        h: 0.5,
        fontSize: 12,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
      });
    } else {
      // --- CONTENT SLIDE LAYOUT ---
      // Slide header
      slide.addText(parsed.title || `Slide ${idx + 1}`, {
        x: 0.8,
        y: 0.5,
        w: 11.5,
        h: 0.8,
        fontSize: 26,
        fontFace: "Arial",
        bold: true,
        color: theme.text,
      });

      // Subtitle
      if (parsed.subtitle) {
        slide.addText(parsed.subtitle, {
          x: 0.8,
          y: 1.25,
          w: 11.5,
          h: 0.45,
          fontSize: 14,
          fontFace: "Calibri",
          color: theme.accent,
        });
      }

      let contentStartY = parsed.subtitle ? 1.85 : 1.5;

      // 1. Render Metrics if present
      if (parsed.metrics.length > 0) {
        const metricCount = Math.min(parsed.metrics.length, 4);
        const cardWidth = (11.6 - (metricCount - 1) * 0.3) / metricCount;

        for (let m = 0; m < metricCount; m++) {
          const item = parsed.metrics[m];
          const cardX = 0.8 + m * (cardWidth + 0.3);

          // Card Background
          slide.addShape(pptx.ShapeType.roundRect, {
            x: cardX,
            y: contentStartY,
            w: cardWidth,
            h: 1.6,
            fill: { color: theme.cardBg },
            line: { color: theme.border, width: 1 },
          });

          // Metric Big Value
          slide.addText(item.value, {
            x: cardX + 0.1,
            y: contentStartY + 0.15,
            w: cardWidth - 0.2,
            h: 0.8,
            fontSize: 28,
            fontFace: "Arial",
            bold: true,
            color: theme.accent,
            align: "center",
          });

          // Metric Label
          slide.addText(item.label, {
            x: cardX + 0.1,
            y: contentStartY + 0.95,
            w: cardWidth - 0.2,
            h: 0.5,
            fontSize: 12,
            fontFace: "Calibri",
            color: theme.subtext,
            align: "center",
          });
        }

        contentStartY += 1.9;
      }

      // 2. Render Tables if present
      if (parsed.tables.length > 0) {
        for (const tableData of parsed.tables) {
          const formattedRows = tableData.map((row, rIdx) => {
            return row.map((cell) => ({
              text: cell,
              options: {
                fill: { color: rIdx === 0 ? theme.cardBg : theme.bg },
                color: rIdx === 0 ? theme.accent : theme.text,
                bold: rIdx === 0,
                fontSize: 12,
                border: { pt: 1, color: theme.border },
              },
            }));
          });

          slide.addTable(formattedRows, {
            x: 0.8,
            y: contentStartY,
            w: 11.6,
            colW: Array(tableData[0]?.length || 1).fill(11.6 / (tableData[0]?.length || 1)),
          });

          contentStartY += tableData.length * 0.45 + 0.4;
        }
      }

      // 3. Render Bullet Points
      if (parsed.bullets.length > 0) {
        const textObjects = parsed.bullets.map((b) => {
          // Detect inline bold highlights
          const isBold = b.startsWith("**") && b.endsWith("**");
          const cleanText = b.replace(/\*\*/g, "");
          return {
            text: cleanText,
            options: {
              bullet: true,
              fontSize: 16,
              fontFace: "Calibri",
              color: theme.text,
              bold: isBold,
              breakLine: true,
              spaceAfter: 10,
            },
          };
        });

        slide.addText(textObjects, {
          x: 0.8,
          y: contentStartY,
          w: 11.6,
          h: Math.max(0.8, 6.4 - contentStartY),
          valign: "top",
        });
      }

      // Footer: slide numbering and platform badge
      slide.addText(`Slide ${idx + 1} of ${totalSlides}`, {
        x: 10.0,
        y: 6.8,
        w: 2.4,
        h: 0.35,
        fontSize: 10,
        fontFace: "Arial",
        color: theme.subtext,
        align: "right",
      });

      slide.addText("Alien AI", {
        x: 0.8,
        y: 6.8,
        w: 3.0,
        h: 0.35,
        fontSize: 10,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
      });
    }
  }

  // Export as uint8array buffer
  const buffer = (await pptx.write({ outputType: "uint8array" })) as Uint8Array;
  return buffer;
}

// CLI Execution entrypoint
if (import.meta.main) {
  try {
    // Read all input from stdin
    const rawInput = await Bun.stdin.text();
    if (!rawInput.trim()) {
      console.error("Error: Expected JSON payload via stdin");
      process.exit(1);
    }

    const payload: PresentationInput = JSON.parse(rawInput);
    if (!payload.slides_markdown) {
      console.error("Error: Missing 'slides_markdown' in input");
      process.exit(1);
    }

    const outIndex = process.argv.indexOf("--out");
    const outPath = outIndex !== -1 ? process.argv[outIndex + 1] : null;

    const buffer = await generatePresentation(payload);

    if (outPath) {
      await Bun.write(outPath, buffer);
      console.error(`Presentation saved successfully to: ${outPath} (${buffer.length} bytes)`);
    } else {
      // Pipe raw binary to stdout
      await Bun.write(Bun.stdout, buffer);
    }
  } catch (err: any) {
    console.error(`Failed to generate presentation: ${err?.message || err}`);
    process.exit(1);
  }
}
