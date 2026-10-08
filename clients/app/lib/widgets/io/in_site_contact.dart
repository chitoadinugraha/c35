import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

const _addCustomerIdPrefix = 'add:';

String siteContactTitleCase(String raw) {
  final q = raw.trim();
  if (q.isEmpty) return q;
  return q
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class InSiteContact extends StatelessWidget {
  const InSiteContact({
    super.key,
    required this.value,
    required this.contacts,
    required this.onCommit,
    this.onAddCustomer,
  });

  final String value;
  final Map<String, SiteContact> contacts;
  final Future<void> Function(String value) onCommit;
  final Future<String?> Function(String name)? onAddCustomer;

  SiteContact? get _contact => value.isEmpty ? null : contacts[value];

  String _label(BuildContext context) {
    final c = _contact;
    if (c == null) return value.isEmpty ? 'site.pos.walkIn'.tr() : value;
    return c.name.isNotEmpty ? c.name : 'Contact ${c.contactId}';
  }

  Future<void> _pick(BuildContext context) async {
    final items = <IoAskItem>[
      IoAskItem(
        id: '',
        title: 'site.pos.walkIn'.tr(),
        subtitle: 'site.pos.walkInSubtitle'.tr(),
        icon: Icons.person_off_outlined,
      ),
      ...contacts.values.map(
        (c) => IoAskItem(
          id: '${c.contactId}',
          title: c.name.isNotEmpty ? c.name : 'Contact ${c.contactId}',
          subtitle: c.phone.isNotEmpty ? c.phone : c.email,
          icon: Icons.person_outline,
        ),
      ),
    ];
    final picked = await ioAskItemsShow(
      context,
      title: 'site.pos.pickCustomer'.tr(),
      items: items,
      searchHint: 'site.pos.searchCustomer'.tr(),
      noMatchItem: onAddCustomer == null
          ? null
          : (q) => IoAskItem(
                id: '$_addCustomerIdPrefix$q',
                title: siteContactTitleCase(q),
                subtitle: 'site.pos.newCustomer'.tr(),
                icon: Icons.person_outline,
                trailingIcon: Icons.add,
                trailingLabel: 'site.pos.addNew'.tr(),
              ),
    );
    if (picked == null) return;
    if (picked.id.startsWith(_addCustomerIdPrefix)) {
      final name = siteContactTitleCase(picked.id.substring(_addCustomerIdPrefix.length));
      final id = await onAddCustomer!(name);
      if (id != null) await onCommit(id);
      return;
    }
    await onCommit(picked.id);
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
                Icon(Icons.person_outline, size: 16, color: _contact == null ? _muted : _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _contact == null ? _muted : _text, fontSize: 13),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20, color: _muted),
              ],
            ),
          ),
        ),
      );
}
