import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class InSiteProduct extends StatelessWidget {
  const InSiteProduct({super.key, required this.value, required this.products, required this.onCommit});

  final String value;
  final Map<String, SiteProduct> products;
  final Future<void> Function(String value) onCommit;

  SiteProduct? get _product => value.isEmpty ? null : products[value];

  String get _label {
    final p = _product;
    if (p == null) return value.isEmpty ? 'Pick product' : value;
    return p.name.isNotEmpty ? p.name : 'Product ${p.productId}';
  }

  Future<void> _pick(BuildContext context) async {
    final items = products.values
        .map((p) => IoAskItem(
              id: '${p.productId}',
              title: p.name.isNotEmpty ? p.name : 'Product ${p.productId}',
              subtitle: p.sku.isNotEmpty ? p.sku : '${p.productId}',
              icon: Icons.inventory_2_outlined,
            ))
        .toList(growable: false);
    final picked = await ioAskItemsShow(context, title: 'Pick product', items: items, searchHint: 'Search products…');
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
                Icon(_product == null ? Icons.add : Icons.inventory_2_outlined, size: 16, color: _product == null ? _muted : _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _product == null ? _muted : _text, fontSize: 13),
                  ),
                ),
                const Icon(Icons.unfold_more, size: 16, color: _muted),
              ],
            ),
          ),
        ),
      );
}
