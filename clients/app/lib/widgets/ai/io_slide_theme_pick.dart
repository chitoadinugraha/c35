import 'package:alienai_c35/c/presentation/presentation_theme_item.dart';
import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:alienai_c35/c/presentation/slide_theme_catalog.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/material.dart';

Future<SlideTheme?> ioSlideThemePick(BuildContext context, {required SlideTheme current}) =>
    uiDialogShow<SlideTheme>(context: context, builder: (_) => _IoSlideThemePickDialog(current: current));

class _IoSlideThemePickDialog extends StatefulWidget {
  const _IoSlideThemePickDialog({required this.current});

  final SlideTheme current;

  @override
  State<_IoSlideThemePickDialog> createState() => _IoSlideThemePickDialogState();
}

class _IoSlideThemePickDialogState extends State<_IoSlideThemePickDialog> {
  late final TextEditingController _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PresentationThemeCatalogItem> get _filtered {
    final q = _query.trim().toLowerCase();
    final items = SlideThemeCatalog.items;
    if (q.isEmpty) return items;
    return items
        .where((t) => t.id.contains(q) || t.displayLabel.toLowerCase().contains(q) || t.aliases.any((a) => a.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) => UiDialog(
        maxWidth: 400,
        padding: uiDialogInsetCompact,
        child: SizedBox(
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiDialogSearchHeader(
                controller: _search,
                hintText: 'Search themes…',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final item = _filtered[i];
                    final theme = item.toSlideTheme();
                    final selected = theme.id == widget.current.id;
                    final accent = item.accentColor;
                    return Material(
                      color: selected ? accent.withValues(alpha: 0.12) : const Color(0xFF100F12),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: ValueKey('slide-theme-${item.id}'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(context, theme),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              if (item.icon.isNotEmpty)
                                UiIcon(item.icon, size: 22, color: accent)
                              else
                                Container(width: 22, height: 22, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.displayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: uiDialogTitleColor,
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: uiDialogBorder)),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_rounded, size: 18, color: accent),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
