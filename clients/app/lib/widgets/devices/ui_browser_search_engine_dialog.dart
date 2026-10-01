import 'package:alienai_c35/c/browser/browser_search_engine.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';

Future<BrowserSearchEngine?> browserSearchEngineDialogShow(
  BuildContext context, {
  required String selectedId,
  List<BrowserSearchEngine> engines = browserSearchEnginesFallback,
}) =>
    uiDialogShow<BrowserSearchEngine>(
      context: context,
      builder: (ctx) => _BrowserSearchEngineDialog(selectedId: selectedId, engines: engines),
    );

class _BrowserSearchEngineDialog extends StatefulWidget {
  const _BrowserSearchEngineDialog({required this.selectedId, required this.engines});

  final String selectedId;
  final List<BrowserSearchEngine> engines;

  @override
  State<_BrowserSearchEngineDialog> createState() => _BrowserSearchEngineDialogState();
}

class _BrowserSearchEngineDialogState extends State<_BrowserSearchEngineDialog> {
  late final TextEditingController _query;
  var _filter = '';

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<BrowserSearchEngine> get _visible {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return widget.engines;
    return widget.engines.where((e) {
      final hay = '${e.name} ${e.description} ${e.id}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => UiDialog(
        maxWidth: 400,
        padding: uiDialogInsetCompact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiDialogSearchHeader(
              controller: _query,
              hintText: 'Filter engines…',
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _visible.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No matches', style: TextStyle(color: uiDialogMuted, fontSize: 13))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final e = _visible[i];
                        final selected = e.id == widget.selectedId;
                        return Material(
                          color: selected ? const Color(0xFF27272A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.pop(context, e),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  _EngineFavicon(engine: e),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.name,
                                          style: TextStyle(
                                            color: uiDialogTitleColor,
                                            fontSize: 14,
                                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                        if (e.description.isNotEmpty)
                                          Text(
                                            e.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: uiDialogMuted, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (selected) const Icon(Icons.check_rounded, size: 20, color: uiDialogAccent),
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
      );
}

class _EngineFavicon extends StatelessWidget {
  const _EngineFavicon({required this.engine});

  final BrowserSearchEngine engine;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.public, size: 20, color: uiDialogMuted);
    final url = engine.faviconUrl.trim();
    if (url.isEmpty) {
      return const SizedBox(width: 24, height: 24, child: Center(child: fallback));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
