import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/tags/tag_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TagHintsFn = Future<List<AssetTagHint>> Function(String prefix);

Future<List<String>?> askTags(
  BuildContext context, {
  List<String> initial = const [],
  String title = 'Tags',
  TagHintsFn? hints,
}) =>
    showDialog<List<String>?>(
      context: context,
      builder: (ctx) => _AskTagsDialog(title: title, initial: initial, hints: hints),
    );

class _AskTagsDialog extends StatefulWidget {
  const _AskTagsDialog({required this.title, required this.initial, this.hints});

  final String title;
  final List<String> initial;
  final TagHintsFn? hints;

  @override
  State<_AskTagsDialog> createState() => _AskTagsDialogState();
}

class _AskTagsDialogState extends State<_AskTagsDialog> {
  late final List<String> _selected = tagsNormalize(widget.initial);
  final _input = TextEditingController();
  String? _err;
  List<AssetTagHint> _hintItems = const [];
  var _hintLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHints('');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadHints(String prefix) async {
    if (widget.hints == null) return;
    setState(() => _hintLoading = true);
    try {
      final items = await widget.hints!(prefix);
      if (!mounted) return;
      setState(() {
        _hintItems = items;
        _hintLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hintItems = const [];
        _hintLoading = false;
      });
    }
  }

  void _addTag(String raw) {
    final e = tagFormatError(raw);
    if (e != null) {
      setState(() => _err = e);
      return;
    }
    final tag = tagNormalize(raw);
    if (tag.isEmpty) return;
    if (_selected.contains(tag)) {
      _input.clear();
      setState(() => _err = null);
      return;
    }
    setState(() {
      _selected.add(tag);
      _err = null;
    });
    _input.clear();
    _loadHints('');
  }

  void _removeTag(String tag) => setState(() => _selected.remove(tag));

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text(widget.title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _selected)
                        InputChip(
                          label: Text('#$tag', style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFFA1A1AA)),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: const Color(0xFF27272A),
                          side: BorderSide.none,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              TextField(
                controller: _input,
                autofocus: true,
                style: const TextStyle(color: Color(0xFFF4F4F5)),
                decoration: InputDecoration(
                  hintText: 'Add tag…',
                  hintStyle: const TextStyle(color: Color(0xFF71717A)),
                  errorText: _err,
                  prefixText: '#',
                  prefixStyle: const TextStyle(color: Color(0xFF71717A)),
                ),
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_#-]')),
                  TextInputFormatter.withFunction((old, neu) {
                    final lower = neu.text.toLowerCase();
                    return lower == neu.text ? neu : neu.copyWith(text: lower);
                  }),
                ],
                onChanged: (v) {
                  setState(() => _err = tagFormatError(v));
                  _loadHints(tagNormalize(v));
                },
                onSubmitted: _addTag,
              ),
              if (widget.hints != null) ...[
                const SizedBox(height: 10),
                Builder(builder: (_) {
                  final prefix = tagNormalize(_input.text);
                  final filtered = [
                    for (final h in _hintItems)
                      if (!_selected.contains(h.tag) && (prefix.isEmpty || h.tag.startsWith(prefix))) h
                  ];
                  if (_hintLoading && filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF71717A)))),
                    );
                  }
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF27272A)),
                      itemBuilder: (_, i) {
                        final h = filtered[i];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text('#${h.tag}', style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 13)),
                          trailing: Text('${h.count}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                          onTap: () => _addTag(h.tag),
                        );
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, <String>[]), child: const Text('Clear')),
          FilledButton(
            onPressed: () {
              if (_input.text.trim().isNotEmpty) _addTag(_input.text);
              if (_err != null) return;
              Navigator.pop(context, List<String>.from(_selected));
            },
            child: const Text('Save'),
          ),
        ],
      );
}
