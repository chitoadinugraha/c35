import 'package:flutter/material.dart';

/// Strips active content from untrusted email HTML before widget render.
String sanitizeMailHtml(String raw) {
  var html = raw;
  if (html.trim().isEmpty) return html;

  const blockTags = ['script', 'iframe', 'object', 'embed', 'form', 'base', 'link', 'meta'];
  for (final tag in blockTags) {
    html = html.replaceAll(
      RegExp('<$tag\\b[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
      '',
    );
    html = html.replaceAll(RegExp('<$tag\\b[^>]*/?>', caseSensitive: false), '');
  }

  html = html.replaceAll(RegExp(r'\s+on\w+\s*=\s*"[^"]*"', caseSensitive: false), '');
  html = html.replaceAll(RegExp(r"\s+on\w+\s*=\s*'[^']*'", caseSensitive: false), '');
  html = html.replaceAll(RegExp(r'\s+on\w+\s*=\s*[^\s>]+', caseSensitive: false), '');
  html = html.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
  html = html.replaceAll(RegExp(r'vbscript:', caseSensitive: false), '');
  return html;
}

String mailHtmlCssColor(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}