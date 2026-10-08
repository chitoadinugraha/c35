import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:flutter/material.dart';

TextStyle guestSiteProductTextStyle(
  SiteProductDesignDraft design,
  String role, {
  Color? fallbackColor,
  double? fallbackSize,
  FontWeight? fallbackWeight,
}) {
  final (size, weight, family, italic, underline, color) = switch (role) {
    'title' => (
        design.titleFontSize,
        design.titleFontWeight,
        design.titleFontFamily,
        design.titleItalic,
        design.titleUnderline,
        design.titleColor,
      ),
    'subtitle' => (
        design.subtitleFontSize,
        design.subtitleFontWeight,
        design.subtitleFontFamily,
        design.subtitleItalic,
        design.subtitleUnderline,
        design.subtitleColor,
      ),
    'price' => (
        design.priceFontSize,
        design.priceFontWeight,
        design.priceFontFamily,
        design.priceItalic,
        design.priceUnderline,
        design.priceColor,
      ),
    _ => (14.0, 'w400', '', false, false, ''),
  };

  final parsedColor = _parseColor(color) ?? fallbackColor;
  return TextStyle(
    fontSize: size,
    fontWeight: _fontWeight(weight) ?? fallbackWeight,
    fontFamily: family.trim().isEmpty ? null : family.trim(),
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    decoration: underline ? TextDecoration.underline : TextDecoration.none,
    color: parsedColor,
  );
}

FontWeight? _fontWeight(String raw) {
  return switch (siteFontWeightNormalize(raw)) {
    'w300' => FontWeight.w300,
    'w400' => FontWeight.w400,
    'w500' => FontWeight.w500,
    'w600' => FontWeight.w600,
    'w700' => FontWeight.w700,
    'w800' => FontWeight.w800,
    'w900' => FontWeight.w900,
    _ => null,
  };
}

Color? _parseColor(String raw) {
  final hex = raw.trim().replaceAll('#', '');
  if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
  if (hex.length == 8) return Color(int.parse(hex, radix: 16));
  return null;
}

SiteProductDesignDraft guestSiteProductDesignFromBoot(Map<String, dynamic> bootJson) {
  final top = bootJson['product_design'];
  if (top is Map<String, dynamic>) return siteProductDesignFromJson(top);
  final meta = bootJson['meta'];
  if (meta is Map<String, dynamic>) return siteProductDesignFromJson(meta['product_design']);
  return const SiteProductDesignDraft();
}
