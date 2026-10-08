import 'package:flutter/material.dart';

const siteEditorMenuRailW = 152.0;
const siteCatalogMasterListW = 280.0;
const siteEditorWideBreakpoint = 900.0;
const siteEditorMasterDetailBreakpoint = 640.0;
const siteEditorFormMaxWidth = 560.0;

const _editorBorder = Color(0xFF3F3F46);

Color siteCatalogMasterDividerColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) return _editorBorder;
  return Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55);
}

Widget siteCatalogMasterDivider(BuildContext context) =>
    ColoredBox(color: siteCatalogMasterDividerColor(context), child: const SizedBox(width: 1));

class UiSiteEditorFormScroll extends StatelessWidget {
  const UiSiteEditorFormScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: siteEditorFormMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ],
      );
}
