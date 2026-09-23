import 'dart:async';

import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/skill/skill_api.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);

Future<SkillCatalog?> ioSkillCatalogPick(BuildContext context, {required SkillApi api}) => showDialog<SkillCatalog>(
      context: context,
      builder: (_) => _IoSkillCatalogDialog(api: api),
    );

class _IoSkillCatalogDialog extends StatefulWidget {
  const _IoSkillCatalogDialog({required this.api});

  final SkillApi api;

  @override
  State<_IoSkillCatalogDialog> createState() => _IoSkillCatalogDialogState();
}

class _IoSkillCatalogDialogState extends State<_IoSkillCatalogDialog> {
  late final _search = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  var _items = <SkillCatalog>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _query('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () => _query(text));
  }

  Future<void> _query(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await widget.api.catalogList(q: q);
    } catch (e) {
      _items = [];
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _sourceAccent(SkillCatalog c) {
    final tags = c.tagsJson.toLowerCase();
    if (tags.contains('openskill') || c.authorName.toLowerCase().contains('openskill')) return const Color(0xFF38BDF8);
    if (c.isVerified) return const Color(0xFF34D399);
    return const Color(0xFFA78BFA);
  }

  String _sourceLabel(SkillCatalog c) {
    final tags = c.tagsJson.toLowerCase();
    if (tags.contains('openskill') || c.authorName.toLowerCase().contains('openskill')) return 'OpenSkill';
    if (c.isVerified) return 'Verified';
    return 'Community';
  }

  @override
  Widget build(BuildContext context) {
    final currency = AppStore.instance.wallet.billingCurrency;
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
      child: SizedBox(
        width: 420,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Skill marketplace', style: TextStyle(color: _title, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Alien catalog + OpenSkill', style: TextStyle(color: _muted, fontSize: 11)),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                style: const TextStyle(color: _title, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search skills…',
                  hintStyle: const TextStyle(color: _muted),
                  prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF100F12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF34D399))),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399)))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center))
                        : _items.isEmpty
                            ? Center(
                                child: Text(
                                  _search.text.trim().isEmpty ? 'No skills in marketplace yet' : 'No matches',
                                  style: const TextStyle(color: _muted, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 4),
                                itemBuilder: (context, i) {
                                  final c = _items[i];
                                  final accent = _sourceAccent(c);
                                  final price = skillCatalogPriceLabel(c, currency: currency);
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => Navigator.pop(context, c),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                                              child: Icon(Icons.auto_awesome_outlined, size: 18, color: accent),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(c.title, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  Text(
                                                    '${c.summary.isNotEmpty ? c.summary : c.authorName} · ${_sourceLabel(c)} · $price',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: _muted, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
