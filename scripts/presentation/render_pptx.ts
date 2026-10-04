import pptxgen from "pptxgenjs";

interface ThemeTokensInput {
  canvas_bg?: string;
  card_bg?: string;
  border?: string;
  accent?: string;
  accent2?: string;
  text?: string;
  subtext?: string;
  badge_bg?: string;
  bullet_card_bg?: string;
  gradient_from?: string;
  gradient_to?: string;
}

interface PresentationInput {
  title?: string;
  eyebrow?: string;
  theme?: string;
  theme_tokens?: ThemeTokensInput;
  prompt?: string;
  slides_markdown: string;
}

interface ThemeConfig {
  id: string;
  name: string;
  bg: string;
  cardBg: string;
  border: string;
  text: string;
  subtext: string;
  accent: string;
  accent2: string;
  badgeBg: string;
}

const THEMES: Record<string, ThemeConfig> = {
  dark: {
    id: "dark",
    name: "Dark Neon",
    bg: "0E0E12",
    cardBg: "181820",
    border: "2A2A36",
    text: "F4F4F5",
    subtext: "A1A1AA",
    accent: "F97316", // Vivid Orange
    accent2: "06B6D4", // Cyan
    badgeBg: "261810",
  },
  midnight: {
    id: "midnight",
    name: "Midnight Indigo",
    bg: "0B0F19",
    cardBg: "141C2E",
    border: "1E2B48",
    text: "F8FAFC",
    subtext: "94A3B8",
    accent: "6366F1", // Electric Indigo
    accent2: "38BDF8", // Sky Blue
    badgeBg: "1E1B4B",
  },
  emerald: {
    id: "emerald",
    name: "Emerald Modern",
    bg: "041C16",
    cardBg: "082E24",
    border: "0E483A",
    text: "ECFDF5",
    subtext: "6EE7B7",
    accent: "10B981", // Emerald
    accent2: "34D399", // Mint
    badgeBg: "064E3B",
  },
  sunset: {
    id: "sunset",
    name: "Sunset Glow",
    bg: "140814",
    cardBg: "241026",
    border: "3D1B42",
    text: "FFF1F2",
    subtext: "FDA4AF",
    accent: "EC4899", // Rose Pink
    accent2: "F59E0B", // Amber
    badgeBg: "3B0764",
  },
  light: {
    id: "light",
    name: "Light Minimal",
    bg: "FFFFFF",
    cardBg: "F8FAFC",
    border: "E2E8F0",
    text: "0F172A",
    subtext: "64748B",
    accent: "2563EB",
    accent2: "0284C7",
    badgeBg: "EFF6FF",
  },
};

function stripHex(color: string): string {
  return color.replace(/^#/, "").trim();
}

function themeFromTokens(id: string, tokens: ThemeTokensInput): ThemeConfig {
  return {
    id,
    name: id,
    bg: stripHex(tokens.canvas_bg || "0D0D11"),
    cardBg: stripHex(tokens.card_bg || "141418"),
    border: stripHex(tokens.border || "26262C"),
    text: stripHex(tokens.text || "F4F4F5"),
    subtext: stripHex(tokens.subtext || "A1A1AA"),
    accent: stripHex(tokens.accent || "F97316"),
    accent2: stripHex(tokens.accent2 || "06B6D4"),
    badgeBg: stripHex(tokens.badge_bg || "261810"),
  };
}

function resolveTheme(name?: string, tokens?: ThemeTokensInput): ThemeConfig {
  if (tokens && Object.keys(tokens).length > 0) {
    const id = (name || "dark").toLowerCase().trim() || "dark";
    return themeFromTokens(id, tokens);
  }
  const key = (name || "dark").toLowerCase().trim();
  switch (key) {
    case "sunset":
    case "coral":
    case "pink":
      return THEMES.sunset;
    case "midnight":
    case "indigo":
      return THEMES.midnight;
    case "emerald":
    case "corporate":
    case "mint":
      return THEMES.emerald;
    case "light":
    case "white":
      return THEMES.light;
    default:
      return THEMES.dark;
  }
}

interface ParsedSlide {
  raw: string;
  title: string;
  subtitle: string;
  imageUrl?: string;
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

  // 2. Extract image markdown ![caption](url)
  let imageUrl: string | undefined;
  const imgMatch = content.match(/!\[(.*?)\]\((.*?)\)/);
  if (imgMatch) {
    imageUrl = imgMatch[2];
    content = content.replace(imgMatch[0], "").trim();
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

    // Bullet points / numbered lists
    if (line.match(/^[-*•]\s+/) || line.match(/^\d+\.\s+/)) {
      const text = line.replace(/^[-*•\d.]+\s+/, "").trim();
      if (text) bullets.push(text);
      continue;
    }

    // Regular line
    if (!title) {
      title = line.replace(/^#+\s*/, "");
    } else if (!subtitle && bullets.length === 0) {
      subtitle = line.replace(/^#+\s*/, "");
    } else {
      bullets.push(line);
    }
  }

  if (currentTable) {
    tables.push(currentTable);
  }

  return { raw: rawText, title, subtitle, imageUrl, bullets, tables, metrics, notes: notes.trim() };
}

export async function generatePresentation(input: PresentationInput): Promise<Uint8Array> {
  const pptx = new pptxgen();

  // 16:9 Widescreen standard layout (13.333 x 7.5 inches)
  pptx.layout = "LAYOUT_16x9";
  pptx.title = input.title || "Alien AI Presentation";
  pptx.author = "Alien AI";
  pptx.company = "Alien AI Platform";
  pptx.subject = input.title || "Generated Presentation";

  const theme = resolveTheme(input.theme, input.theme_tokens);

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

    // Explicit solid background matching the active theme
    slide.background = { color: theme.bg };

    // Attach speaker notes if any
    if (parsed.notes) {
      slide.addNotes(parsed.notes);
    }

    // Top decorative accent line across the slide (13.333 inches widescreen)
    slide.addShape(pptx.ShapeType.rect, {
      x: 0,
      y: 0,
      w: 13.333,
      h: 0.08,
      fill: { color: theme.accent },
      line: { color: theme.accent },
    });

    const isCoverSlide = idx === 0 && parsed.bullets.length === 0 && parsed.tables.length === 0 && parsed.metrics.length === 0;

    if (isCoverSlide) {
      // ==========================================
      // COVER / TITLE SLIDE LAYOUT
      // ==========================================

      // Eyebrow badge pill
      const eyebrowText = (input.eyebrow || input.prompt || "PRESENTATION").toUpperCase();
      const hasCoverImage = Boolean(parsed.imageUrl);
      const textWidth = hasCoverImage ? 6.8 : 11.7;

      slide.addShape(pptx.ShapeType.roundRect, {
        x: 0.8,
        y: 1.4,
        w: 2.4,
        h: 0.38,
        rectRadius: 0.1,
        fill: { color: theme.badgeBg },
        line: { color: theme.accent, width: 1 },
      });
      slide.addText(eyebrowText, {
        x: 0.8,
        y: 1.4,
        w: 2.4,
        h: 0.38,
        fontSize: 10,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
        align: "center",
        valign: "middle",
      });

      // Main large title (high contrast crisp text)
      slide.addText(parsed.title || input.title || "Presentation", {
        x: 0.8,
        y: 2.0,
        w: textWidth,
        h: 1.8,
        fontSize: 36,
        fontFace: "Arial",
        bold: true,
        color: theme.text,
        valign: "middle",
      });

      // Subtitle
      if (parsed.subtitle) {
        slide.addText(parsed.subtitle, {
          x: 0.8,
          y: 4.0,
          w: textWidth,
          h: 1.0,
          fontSize: 16,
          fontFace: "Calibri",
          color: theme.subtext,
          valign: "top",
        });
      }

      // Horizontal Accent Divider Line
      slide.addShape(pptx.ShapeType.rect, {
        x: 0.8,
        y: parsed.subtitle ? 5.1 : 4.2,
        w: 0.9,
        h: 0.05,
        fill: { color: theme.accent },
        line: { color: theme.accent },
      });

      // Cover image if present
      if (hasCoverImage && parsed.imageUrl) {
        const imageX = 8.0;
        const imageY = 1.4;
        const imageW = 4.5;
        const imageH = 4.8;

        slide.addShape(pptx.ShapeType.roundRect, {
          x: imageX,
          y: imageY,
          w: imageW,
          h: imageH,
          rectRadius: 0.1,
          fill: { color: theme.cardBg },
          line: { color: theme.border, width: 1 },
        });

        try {
          slide.addImage({
            path: parsed.imageUrl,
            x: imageX + 0.1,
            y: imageY + 0.1,
            w: imageW - 0.2,
            h: imageH - 0.2,
            sizing: { type: "contain" },
          });
        } catch {
          slide.addText("Cover Image", {
            x: imageX,
            y: imageY + imageH / 2 - 0.3,
            w: imageW,
            h: 0.6,
            fontSize: 12,
            color: theme.subtext,
            align: "center",
          });
        }
      }

      // Bottom Slide Indicator Dots (Matching Flutter Preview & PDF!)
      const dotsStartX = 6.666 - (totalSlides * 0.25) / 2;
      for (let d = 0; d < totalSlides; d++) {
        const isCurrent = d === idx;
        slide.addShape(pptx.ShapeType.roundRect, {
          x: dotsStartX + d * 0.25,
          y: 6.85,
          w: isCurrent ? 0.35 : 0.12,
          h: 0.07,
          rectRadius: 0.035,
          fill: { color: isCurrent ? theme.accent : "333344" },
          line: { color: isCurrent ? theme.accent : "333344" },
        });
      }

      // Bottom Branding & Counter
      slide.addText("Alien AI", {
        x: 0.8,
        y: 6.8,
        w: 3.0,
        h: 0.35,
        fontSize: 9,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
      });

      slide.addText(`Slide 1 of ${totalSlides}`, {
        x: 10.0,
        y: 6.8,
        w: 2.5,
        h: 0.35,
        fontSize: 9,
        fontFace: "Arial",
        color: theme.subtext,
        align: "right",
      });
    } else {
      // ==========================================
      // CONTENT SLIDE LAYOUT (Matching App Preview!)
      // ==========================================

      // 1. Slide header pill badge: SLIDE X OF Y
      slide.addShape(pptx.ShapeType.roundRect, {
        x: 0.8,
        y: 0.45,
        w: 1.7,
        h: 0.34,
        rectRadius: 0.08,
        fill: { color: theme.badgeBg },
        line: { color: theme.border, width: 0.8 },
      });
      slide.addText(`SLIDE ${idx + 1} OF ${totalSlides}`, {
        x: 0.8,
        y: 0.45,
        w: 1.7,
        h: 0.34,
        fontSize: 9,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
        align: "center",
        valign: "middle",
      });

      // 2. Slide Title
      slide.addText(parsed.title || `Slide ${idx + 1}`, {
        x: 0.8,
        y: 0.9,
        w: 11.7,
        h: 0.65,
        fontSize: 24,
        fontFace: "Arial",
        bold: true,
        color: theme.text,
        valign: "middle",
      });

      // 3. Subtitle (if present)
      let contentStartY = 1.7;
      if (parsed.subtitle) {
        slide.addText(parsed.subtitle, {
          x: 0.8,
          y: 1.55,
          w: 11.7,
          h: 0.35,
          fontSize: 13,
          fontFace: "Calibri",
          color: theme.subtext,
        });
        contentStartY = 2.05;
      }

      // Check if image is present for split layout
      const hasImage = Boolean(parsed.imageUrl);
      const contentWidth = hasImage ? 6.8 : 11.7;

      // 4. Render Metrics if present
      if (parsed.metrics.length > 0) {
        const metricCount = Math.min(parsed.metrics.length, 3);
        const cardWidth = (contentWidth - (metricCount - 1) * 0.25) / metricCount;

        for (let m = 0; m < metricCount; m++) {
          const item = parsed.metrics[m];
          const cardX = 0.8 + m * (cardWidth + 0.25);

          slide.addShape(pptx.ShapeType.roundRect, {
            x: cardX,
            y: contentStartY,
            w: cardWidth,
            h: 1.3,
            rectRadius: 0.1,
            fill: { color: theme.cardBg },
            line: { color: theme.border, width: 1 },
          });

          slide.addText(item.value, {
            x: cardX + 0.1,
            y: contentStartY + 0.15,
            w: cardWidth - 0.2,
            h: 0.6,
            fontSize: 24,
            fontFace: "Arial",
            bold: true,
            color: theme.accent,
            align: "center",
          });

          slide.addText(item.label, {
            x: cardX + 0.1,
            y: contentStartY + 0.75,
            w: cardWidth - 0.2,
            h: 0.45,
            fontSize: 11,
            fontFace: "Calibri",
            color: theme.subtext,
            align: "center",
          });
        }

        contentStartY += 1.5;
      }

      // 5. Render Bullet Items as Rounded Cards (Matching Flutter Preview!)
      if (parsed.bullets.length > 0) {
        const count = parsed.bullets.length;
        const availableHeight = 6.4 - contentStartY;
        const maxCardH = Math.min(1.05, Math.max(0.65, (availableHeight - (count - 1) * 0.14) / count));
        const spacing = Math.min(0.2, Math.max(0.1, (availableHeight - count * maxCardH) / (count > 1 ? count - 1 : 1)));

        for (let bIdx = 0; bIdx < count; bIdx++) {
          const rawBullet = parsed.bullets[bIdx];
          const cleanText = rawBullet.replace(/^\d+\.\s*/, "").replace(/^[-*•]\s*/, "");
          const cardY = contentStartY + bIdx * (maxCardH + spacing);

          // Card Background Container
          slide.addShape(pptx.ShapeType.roundRect, {
            x: 0.8,
            y: cardY,
            w: contentWidth,
            h: maxCardH,
            rectRadius: 0.1,
            fill: { color: theme.cardBg },
            line: { color: theme.border, width: 1 },
          });

          // Numbered Badge Circle
          const badgeD = Math.min(0.44, maxCardH - 0.22);
          const badgeY = cardY + (maxCardH - badgeD) / 2;
          slide.addShape(pptx.ShapeType.ellipse, {
            x: 1.05,
            y: badgeY,
            w: badgeD,
            h: badgeD,
            fill: { color: theme.accent },
            line: { color: theme.accent },
          });

          slide.addText(String(bIdx + 1), {
            x: 1.05,
            y: badgeY,
            w: badgeD,
            h: badgeD,
            fontSize: 11,
            fontFace: "Arial",
            bold: true,
            color: "FFFFFF",
            align: "center",
            valign: "middle",
          });

          // Card Item Text
          slide.addText(cleanText, {
            x: 1.65,
            y: cardY,
            w: contentWidth - 0.95,
            h: maxCardH,
            fontSize: count <= 3 ? 14 : 12.5,
            fontFace: "Calibri",
            color: theme.text,
            valign: "middle",
          });
        }
      }

      // 6. Tables if present
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
            w: contentWidth,
            colW: Array(tableData[0]?.length || 1).fill(contentWidth / (tableData[0]?.length || 1)),
          });

          contentStartY += tableData.length * 0.45 + 0.3;
        }
      }

      // 7. Right Image Container (Split Layout)
      if (hasImage && parsed.imageUrl) {
        const imageX = 8.0;
        const imageY = 1.7;
        const imageW = 4.5;
        const imageH = 4.6;

        slide.addShape(pptx.ShapeType.roundRect, {
          x: imageX,
          y: imageY,
          w: imageW,
          h: imageH,
          rectRadius: 0.1,
          fill: { color: theme.cardBg },
          line: { color: theme.border, width: 1 },
        });

        // Add image (if local or http url)
        try {
          slide.addImage({
            path: parsed.imageUrl,
            x: imageX + 0.1,
            y: imageY + 0.1,
            w: imageW - 0.2,
            h: imageH - 0.2,
            sizing: { type: "contain" },
          });
        } catch {
          // If remote image fails to fetch during offline export, display caption placeholder
          slide.addText("Image preview", {
            x: imageX,
            y: imageY + imageH / 2 - 0.3,
            w: imageW,
            h: 0.6,
            fontSize: 12,
            color: theme.subtext,
            align: "center",
          });
        }
      }

      // 8. Bottom Slide Indicator Dots (Matching Flutter Preview!)
      const dotsStartX = 6.666 - (totalSlides * 0.25) / 2;
      for (let d = 0; d < totalSlides; d++) {
        const isCurrent = d === idx;
        slide.addShape(pptx.ShapeType.roundRect, {
          x: dotsStartX + d * 0.25,
          y: 6.85,
          w: isCurrent ? 0.35 : 0.12,
          h: 0.07,
          rectRadius: 0.035,
          fill: { color: isCurrent ? theme.accent : "333344" },
          line: { color: isCurrent ? theme.accent : "333344" },
        });
      }

      // Footer branding
      slide.addText("Alien AI", {
        x: 0.8,
        y: 6.8,
        w: 3.0,
        h: 0.35,
        fontSize: 9,
        fontFace: "Arial",
        bold: true,
        color: theme.accent,
      });

      slide.addText(`Slide ${idx + 1} of ${totalSlides}`, {
        x: 10.0,
        y: 6.8,
        w: 2.5,
        h: 0.35,
        fontSize: 9,
        fontFace: "Arial",
        color: theme.subtext,
        align: "right",
      });
    }
  }

  // Export buffer
  const buffer = (await pptx.write({ outputType: "uint8array" })) as Uint8Array;
  return buffer;
}

// CLI Execution entrypoint
if (import.meta.main) {
  try {
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
      await Bun.write(Bun.stdout, buffer);
    }
  } catch (err: any) {
    console.error(`Failed to generate presentation: ${err?.message || err}`);
    process.exit(1);
  }
}
