import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class InSiteContact extends StatelessWidget {
  const InSiteContact({super.key, required this.value, required this.contacts, required this.onCommit});

  final String value;
  final Map<String, SiteContact> contacts;
  final Future<void> Function(String value) onCommit;

  SiteContact? get _contact => value.isEmpty ? null : contacts[value];

  String get _label {
    final c = _contact;
    if (c == null) return value.isEmpty ? 'Pick contact' : value;
    return c.name.isNotEmpty ? c.name : 'Contact ${c.contactId}';
  }

  Future<void> _pick(BuildContext context) async {
    final items = contacts.values
        .map((c) => IoAskItem(
              id: '${c.contactId}',
              title: c.name.isNotEmpty ? c.name : 'Contact ${c.contactId}',
              subtitle: c.phone.isNotEmpty ? c.phone : c.email,
              icon: Icons.person_outline,
            ))
        .toList(growable: false);
    final picked = await ioAskItemsShow(context, title: 'Pick contact', items: items, searchHint: 'Search contacts…');
    if (picked != null) await onCommit(picked.id);
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pick(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(_contact == null ? Icons.add : Icons.person_outline, size: 16, color: _contact == null ? _muted : _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _contact == null ? _muted : _text, fontSize: 13),
                  ),
                ),
                const Icon(Icons.unfold_more, size: 16, color: _muted),
              ],
            ),
          ),
        ),
      );
}
