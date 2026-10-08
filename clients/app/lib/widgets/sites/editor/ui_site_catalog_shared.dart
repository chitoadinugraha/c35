import 'package:flutter/material.dart';

const siteEditorMenuRailW = 152.0;
const siteCatalogMasterListW = 280.0;
const siteEditorWideBreakpoint = 900.0;
const siteEditorMasterDetailBreakpoint = 640.0;
const siteEditorFormMaxWidth = 560.0;
const siteEditorPreviewPaneW = 420.0;
const siteEditorPreviewBreakpoint = 1180.0;

bool siteEditorShowPreviewPane(double width) => width >= siteEditorPreviewBreakpoint;

const _editorBorder = Color(0xFF3F3F46);

Color siteCatalogMasterDividerColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) return _editorBorder;
  return Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55);
}

Widget siteCatalogMasterDivider(BuildContext context) =>
    ColoredBox(color: siteCatalogMasterDividerColor(context), child: const SizedBox(width: 1));

/// Palette toggle before catalog `+` — opens block appearance editors.
Widget siteCatalogPaletteButton({required bool selected, required VoidCallback onPressed, String tooltip = 'Appearance'}) {
  return Builder(
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          selected ? Icons.palette : Icons.palette_outlined,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        ),
      );
    },
  );
}

Future<bool> siteCatalogConfirmDelete(
  BuildContext context, {
  required String title,
  String? body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null || body.isEmpty ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}

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
