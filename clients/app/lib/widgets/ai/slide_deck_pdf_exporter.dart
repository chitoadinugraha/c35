import 'dart:typed_data';
import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:alienai_c35/widgets/ai/ui_slide_deck_card.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SlideDeckPdfExporter {
  /// Generates and triggers the native sharing / saving of a PDF slide deck.
  static Future<void> export(SlideDeckData deck, SlideTheme theme) async {
    final bytes = await generatePdf(deck, theme);
    final safeTitle = _sanitizeFilename(deck.title);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$safeTitle.pdf',
    );
  }

  static String _sanitizeFilename(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'presentation' : cleaned;
  }

  static PdfColor _toPdfColor(Color c) {
    return PdfColor(c.r, c.g, c.b, c.a);
  }

  /// Builds the complete PDF document with 16:9 widescreen presentation layout
  /// perfectly matching UiSlideDeckCard and render_pptx.
  static Future<Uint8List> generatePdf(SlideDeckData deck, SlideTheme theme) async {
    final pdf = pw.Document(
      title: deck.title,
      author: 'Alien AI',
      creator: 'Alien AI Slides',
    );

    // Standard 16:9 widescreen presentation dimensions in PDF points (960 x 540)
    const pageFormat = PdfPageFormat(960, 540, marginAll: 0);

    final canvasBgCol = _toPdfColor(theme.canvasBg);
    final accentCol = _toPdfColor(theme.accent);
    final textPrimaryCol = _toPdfColor(theme.textPrimary);
    final textSecondaryCol = _toPdfColor(theme.textSecondary);
    final cardBgCol = _toPdfColor(theme.bulletCardBg);
    final borderCol = _toPdfColor(theme.border);

    final totalSlides = deck.slides.length;

    // Pre-parse slides and prefetch images
    final parsedSlides = <_ParsedSlide>[];
    final slideImages = <int, pw.MemoryImage>{};

    for (var i = 0; i < totalSlides; i++) {
      final parsed = _parseSlideContent(deck.slides[i]);
      parsedSlides.add(parsed);

      if (parsed.imageUrl != null && parsed.imageUrl!.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(parsed.imageUrl!)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            slideImages[i] = pw.MemoryImage(res.bodyBytes);
          }
        } catch (_) {}
      }
    }

    for (var i = 0; i < totalSlides; i++) {
      final parsed = parsedSlides[i];
      final isFirstSlide = i == 0;
      final isTitleCover = isFirstSlide && parsed.bullets.isEmpty && parsed.metrics.isEmpty && parsed.tables.isEmpty;
      final img = slideImages[i];

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Container(
              width: 960,
              height: 540,
              color: canvasBgCol,
              child: pw.Stack(
                children: [
                  // Top decorative accent line (full width 960, 4pt height)
                  pw.Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: pw.Container(height: 4, color: accentCol),
                  ),

                  // Slide content canvas
                  pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(56, 34, 56, 26),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Header pill badge
                        if (isTitleCover)
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: cardBgCol,
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: accentCol, width: 1),
                            ),
                            child: pw.Text(
                              (deck.eyebrow?.isNotEmpty == true ? deck.eyebrow! : 'PRESENTATION').toUpperCase(),
                              style: pw.TextStyle(
                                color: accentCol,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                        else
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: cardBgCol,
                              borderRadius: pw.BorderRadius.circular(5),
                              border: pw.Border.all(color: accentCol, width: 0.8),
                            ),
                            child: pw.Text(
                              'SLIDE ${i + 1} OF $totalSlides',
                              style: pw.TextStyle(
                                color: accentCol,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                        pw.SizedBox(height: isTitleCover ? 28 : 12),

                        // Main Slide Body (Cover or Content)
                        pw.Expanded(
                          child: isTitleCover
                              ? _buildTitleCoverBody(
                                  deck: deck,
                                  parsed: parsed,
                                  image: img,
                                  accentCol: accentCol,
                                  textPrimaryCol: textPrimaryCol,
                                  textSecondaryCol: textSecondaryCol,
                                  cardBgCol: cardBgCol,
                                  borderCol: borderCol,
                                )
                              : _buildSlideContentBody(
                                  parsed: parsed,
                                  image: img,
                                  accentCol: accentCol,
                                  textPrimaryCol: textPrimaryCol,
                                  textSecondaryCol: textSecondaryCol,
                                  cardBgCol: cardBgCol,
                                  borderCol: borderCol,
                                ),
                        ),

                        // Bottom Navigation & Branding Bar (Identical to Preview & PPTX)
                        pw.SizedBox(height: 14),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // Left Alien AI branding
                            pw.Text(
                              'Alien AI',
                              style: pw.TextStyle(
                                color: accentCol,
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            // Center slide indicator progress capsules
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                for (var d = 0; d < totalSlides; d++)
                                  pw.Container(
                                    margin: const pw.EdgeInsets.symmetric(horizontal: 2.5),
                                    width: d == i ? 22 : 6,
                                    height: 4,
                                    decoration: pw.BoxDecoration(
                                      color: d == i ? accentCol : borderCol,
                                      borderRadius: pw.BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),

                            // Right slide counter
                            pw.Text(
                              'Slide ${i + 1} of $totalSlides',
                              style: pw.TextStyle(
                                color: textSecondaryCol,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildTitleCoverBody({
    required SlideDeckData deck,
    required _ParsedSlide parsed,
    required pw.MemoryImage? image,
    required PdfColor accentCol,
    required PdfColor textPrimaryCol,
    required PdfColor textSecondaryCol,
    required PdfColor cardBgCol,
    required PdfColor borderCol,
  }) {
    final titleText = parsed.title.isNotEmpty ? parsed.title : deck.title;

    final textContent = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          titleText,
          style: pw.TextStyle(
            color: textPrimaryCol,
            fontSize: 36,
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 1.2,
          ),
        ),
        if (parsed.subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            parsed.subtitle,
            style: pw.TextStyle(
              color: textSecondaryCol,
              fontSize: 16,
              lineSpacing: 1.4,
            ),
          ),
        ],
        pw.SizedBox(height: 20),
        // Horizontal accent divider line
        pw.Container(
          width: 64,
          height: 4,
          decoration: pw.BoxDecoration(
            color: accentCol,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
      ],
    );

    if (image != null) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(flex: 6, child: textContent),
          pw.SizedBox(width: 24),
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: 330,
              decoration: pw.BoxDecoration(
                color: cardBgCol,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: borderCol, width: 1),
              ),
              padding: const pw.EdgeInsets.all(6),
              alignment: pw.Alignment.center,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        ],
      );
    }

    return textContent;
  }

  static pw.Widget _buildSlideContentBody({
    required _ParsedSlide parsed,
    required pw.MemoryImage? image,
    required PdfColor accentCol,
    required PdfColor textPrimaryCol,
    required PdfColor textSecondaryCol,
    required PdfColor cardBgCol,
    required PdfColor borderCol,
  }) {
    final contentColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Slide Title
        if (parsed.title.isNotEmpty) ...[
          pw.Text(
            parsed.title,
            style: pw.TextStyle(
              color: textPrimaryCol,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
        ],

        // Slide Subtitle
        if (parsed.subtitle.isNotEmpty) ...[
          pw.Text(
            parsed.subtitle,
            style: pw.TextStyle(
              color: textSecondaryCol,
              fontSize: 13,
            ),
          ),
          pw.SizedBox(height: 14),
        ] else if (parsed.title.isNotEmpty) ...[
          pw.SizedBox(height: 12),
        ],

        // Metrics badges row
        if (parsed.metrics.isNotEmpty) ...[
          pw.Wrap(
            spacing: 12,
            runSpacing: 10,
            children: parsed.metrics.map((m) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: cardBgCol,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: accentCol, width: 1),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      m.value,
                      style: pw.TextStyle(
                        color: accentCol,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (m.label.isNotEmpty) ...[
                      pw.SizedBox(width: 8),
                      pw.Text(
                        m.label,
                        style: pw.TextStyle(
                          color: textPrimaryCol,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 14),
        ],

        // Bullets rendered as Numbered Rounded Cards (Matching Flutter Preview & PPTX!)
        if (parsed.bullets.isNotEmpty)
          pw.Expanded(
            child: pw.ListView.builder(
              itemCount: parsed.bullets.length,
              itemBuilder: (ctx, idx) {
                final rawBullet = parsed.bullets[idx];
                final cleanBullet = rawBullet.replaceFirst(RegExp(r'^[-*•\d\.]+\s*'), '');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: cardBgCol,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: borderCol, width: 1),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Numbered circular badge on left
                      pw.Container(
                        width: 24,
                        height: 24,
                        margin: const pw.EdgeInsets.only(right: 14),
                        decoration: pw.BoxDecoration(
                          color: accentCol,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '${idx + 1}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      // Card bullet text
                      pw.Expanded(
                        child: pw.Text(
                          cleanBullet,
                          style: pw.TextStyle(
                            color: textPrimaryCol,
                            fontSize: parsed.bullets.length <= 3 ? 15 : 13.5,
                            lineSpacing: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Tables
        if (parsed.tables.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: parsed.tables.map((tableRows) {
                return pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: borderCol, width: 0.6),
                  headerStyle: pw.TextStyle(color: textPrimaryCol, fontWeight: pw.FontWeight.bold, fontSize: 11),
                  headerDecoration: pw.BoxDecoration(color: cardBgCol),
                  cellStyle: pw.TextStyle(color: textPrimaryCol, fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  data: tableRows,
                );
              }).toList(),
            ),
          ),
      ],
    );

    if (image != null) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(flex: 6, child: contentColumn),
          pw.SizedBox(width: 24),
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: 330,
              decoration: pw.BoxDecoration(
                color: cardBgCol,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: borderCol, width: 1),
              ),
              padding: const pw.EdgeInsets.all(6),
              alignment: pw.Alignment.center,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        ],
      );
    }

    return contentColumn;
  }

  static _ParsedSlide _parseSlideContent(String rawText) {
    var content = rawText.trim();

    // Strip HTML notes
    content = content.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '').trim();

    // Extract image markdown ![caption](url)
    String? imageUrl;
    final imgMatch = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(content);
    if (imgMatch != null) {
      imageUrl = imgMatch.group(2);
      content = content.replaceFirst(imgMatch.group(0)!, '').trim();
    }

    final lines = content.split('\n').map((l) => l.trimRight()).toList();
    var title = '';
    var subtitle = '';
    final bullets = <String>[];
    final metrics = <_Metric>[];
    final tables = <List<List<String>>>[];

    List<List<String>>? currentTable;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (currentTable != null) {
          tables.add(currentTable);
          currentTable = null;
        }
        continue;
      }

      // Markdown Table row
      if (line.startsWith('|') && line.endsWith('|')) {
        final cells = line.split('|').map((c) => c.trim()).toList();
        if (cells.length >= 3) {
          final row = cells.sublist(1, cells.length - 1);
          if (row.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) {
            continue; // separator row
          }
          currentTable ??= [];
          currentTable.add(row);
          continue;
        }
      } else if (currentTable != null) {
        tables.add(currentTable);
        currentTable = null;
      }

      // Title
      if (line.startsWith('# ') && title.isEmpty) {
        title = line.replaceFirst(RegExp(r'^#\s+'), '').trim();
        continue;
      }

      // Subtitle
      if (line.startsWith('## ') && subtitle.isEmpty) {
        subtitle = line.replaceFirst(RegExp(r'^##\s+'), '').trim();
        continue;
      }

      // Metric
      final metricMatch = RegExp(r'^(?:>\s*)?\*\*([+$€£¥\d.,%]+[KkMmBbTt]?)\*\*\s*[:\-–—]?\s*(.*)$').firstMatch(line);
      if (metricMatch != null) {
        final val = metricMatch.group(1)?.trim() ?? '';
        final lbl = metricMatch.group(2)?.trim() ?? '';
        if (val.isNotEmpty) {
          metrics.add(_Metric(value: val, label: lbl));
          continue;
        }
      }

      // Bullet
      if (RegExp(r'^[-*•]\s+').hasMatch(line) || RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final txt = line.replaceFirst(RegExp(r'^[-*•\d.]+\s+'), '').trim();
        if (txt.isNotEmpty) bullets.add(txt);
        continue;
      }

      // Regular line
      if (title.isEmpty) {
        title = line;
      } else if (subtitle.isEmpty && bullets.isEmpty) {
        subtitle = line;
      } else {
        bullets.add(line);
      }
    }

    if (currentTable != null) {
      tables.add(currentTable);
    }

    return _ParsedSlide(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      bullets: bullets,
      metrics: metrics,
      tables: tables,
    );
  }
}

class _Metric {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});
}

class _ParsedSlide {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final List<String> bullets;
  final List<_Metric> metrics;
  final List<List<List<String>>> tables;

  const _ParsedSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.bullets,
    required this.metrics,
    required this.tables,
  });
}
