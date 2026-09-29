import 'package:alienai_c35/c/browser/browser_search_engine.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _border = Color(0xFF3F3F46);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<BrowserSearchEngine?> browserSearchEngineDialogShow(
  BuildContext context, {
  required String selectedId,
  List<BrowserSearchEngine> engines = browserSearchEnginesFallback,
}) =>
    showDialog<BrowserSearchEngine>(
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
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: const Text('Search engine', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _query,
                autofocus: true,
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Filter engines…',
                  hintStyle: const TextStyle(color: _muted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _muted),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: _visible.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No matches', style: TextStyle(color: _muted, fontSize: 13))),
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
                                              color: _text,
                                              fontSize: 14,
                                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                          if (e.description.isNotEmpty)
                                            Text(
                                              e.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: _muted, fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected) const Icon(Icons.check_rounded, size: 20, color: _accent),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
        ],
      );
}

class _EngineFavicon extends StatelessWidget {
  const _EngineFavicon({required this.engine});

  final BrowserSearchEngine engine;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.public, size: 20, color: _muted);
    final url = engine.faviconUrl.trim();
    if (url.isEmpty) {
      return SizedBox(width: 24, height: 24, child: Center(child: fallback));
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
