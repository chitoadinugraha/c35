import 'package:flutter/material.dart';

import 'site_card_style.dart';
import 'site_color.dart';
import 'site_design_models.dart';
import 'site_design_store.dart';
import 'site_theme.dart';

class SiteResolvedDesign {
  const SiteResolvedDesign({
    required this.theme,
    required this.themeBaseId,
    required this.background,
    required this.backdrop,
    required this.cardStyle,
    required this.blockStyles,
    this.productDesign = const SiteProductDesignDraft(),
  });

  /// User-selected palette (light/dark from [SiteDesignStore.themeDark]).
  final SiteThemeTokens theme;
  final String themeBaseId;
  final SiteBackgroundDraft background;
  final SiteBackdropDraft backdrop;
  final SiteCardStyleDraft cardStyle;
  final Map<String, SiteBlockDesignDraft> blockStyles;
  final SiteProductDesignDraft productDesign;

  Color get pageBackground {
    if (background.type == 'color' && background.color.isNotEmpty) {
      return siteColorParse(background.color);
    }
    return theme.background;
  }

  /// Readable on [pageBackground]; cards still use [theme] surfaces.
  SiteThemeTokens get _canvasTokens =>
      siteThemeTokensOnCanvas(themeBaseId, pageBackground, background, theme);

  Color get fg => _canvasTokens.onSurface;
  Color get muted => _canvasTokens.onSurfaceVariant;
  Color get primary => _canvasTokens.primary;

  bool isBare(String block) {
    final override = blockStyles[block];
    return override != null && override.isBare;
  }

  SiteCardDecoration cardFor(String block) {
    final override = blockStyles[block];
    if (override != null && !override.inheritsGlobal && !override.isBare) {
      return siteCardDecorationResolve(style: SiteCardStyleDraft(id: override.cardStyleId, params: override.params), theme: theme);
    }
    return siteCardDecorationResolve(style: cardStyle, theme: theme);
  }
}

/// Text/accent on a custom solid page color when it disagrees with selected light/dark.
SiteThemeTokens siteThemeTokensOnCanvas(
  String baseId,
  Color canvas,
  SiteBackgroundDraft background,
  SiteThemeTokens selected,
) {
  if (background.type != 'color' || background.color.trim().isEmpty) return selected;
  final canvasDark = canvas.computeLuminance() < 0.45;
  if (canvasDark == selected.isDark) return selected;
  return siteThemeResolve(baseId, canvasDark).tokens;
}

SiteResolvedDesign siteDesignResolve(SiteDesignStore draft) => SiteResolvedDesign(
      theme: siteThemeResolve(draft.themeBaseId, draft.themeDark).tokens,
      themeBaseId: draft.themeBaseId,
      background: draft.background,
      backdrop: draft.backdrop,
      cardStyle: draft.cardStyle,
      blockStyles: {for (final b in draft.blockDesigns) b.block: b},
      productDesign: draft.productDesign,
    );

SiteThemeTokens siteDesignSelectedTheme(SiteDesignStore draft) =>
    siteThemeResolve(draft.themeBaseId, draft.themeDark).tokens;

bool siteBackgroundConflictsTheme(SiteBackgroundDraft bg, bool themeDark) {
  if (bg.type != 'color' || bg.color.trim().isEmpty) return false;
  final canvasDark = siteColorParse(bg.color).computeLuminance() < 0.45;
  return canvasDark != themeDark;
}

/// Drop a solid page color that fights the selected light/dark mode (e.g. #000 while Light).
SiteBackgroundDraft siteBackgroundAlignToTheme(SiteBackgroundDraft bg, bool themeDark) =>
    siteBackgroundConflictsTheme(bg, themeDark) ? const SiteBackgroundDraft() : bg;
