import 'package:alienai_c35/c/browser/browser_search_engine.dart';
import 'package:flutter/material.dart';

Future<BrowserSearchEngine?> browserSearchEngineDialogShow(
  BuildContext context, {
  required String selectedId,
  List<BrowserSearchEngine> engines = browserSearchEnginesFallback,
}) =>
    showDialog<BrowserSearchEngine>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Search engine', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
        children: [
          for (final e in engines)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e),
              child: Row(
                children: [
                  if (e.id == selectedId) const Icon(Icons.check_rounded, size: 18, color: Color(0xFF34D399)),
                  if (e.id == selectedId) const SizedBox(width: 8),
                  Expanded(child: Text(e.name, style: const TextStyle(color: Color(0xFFF4F4F5)))),
                ],
              ),
            ),
        ],
      ),
    );