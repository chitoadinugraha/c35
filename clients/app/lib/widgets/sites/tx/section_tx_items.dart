import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class SectionTxItems extends StatelessWidget {
  const SectionTxItems({
    super.key,
    required this.items,
    required this.products,
    required this.onChanged,
  });

  final List<TxItem> items;
  final List<SiteProduct> products;
  final ValueChanged<List<TxItem>> onChanged;

  Map<Int64, SiteProduct> get _productById => {for (final p in products) p.productId: p};

  Int64 _lineTotal(TxItem item) => Int64(item.qty) * item.price;

  void _addProduct(SiteProduct product) {
    final existing = items.where((i) => i.productId == product.productId).firstOrNull;
    if (existing != null) {
      onChanged(items.map((i) => i.productId == product.productId ? (i.clone()..qty = i.qty + 1) : i).toList(growable: false));
      return;
    }
    onChanged([
      ...items,
      TxItem(productId: product.productId, qty: 1, price: product.price > Int64.ZERO ? product.price : Int64.ZERO),
    ]);
  }

  void _updateQty(int index, int qty) {
    if (qty <= 0) {
      onChanged([...items]..removeAt(index));
      return;
    }
    onChanged(items.asMap().entries.map((e) => e.key == index ? (e.value.clone()..qty = qty) : e.value).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final sellable = products.where((p) => p.canSell && !p.isArchived).toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Catalog', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: sellable.isEmpty
                    ? const Center(child: Text('No sellable products', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: sellable.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final p = sellable[i];
                          return ListTile(
                            dense: true,
                            title: Text(p.name, style: const TextStyle(color: _text, fontSize: 14)),
                            subtitle: Text(
                              p.price > Int64.ZERO ? moneyFmtIdr(p.price.toInt()) : 'No price',
                              style: const TextStyle(color: _muted, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: _accent),
                              onPressed: () => _addProduct(p),
                            ),
                            onTap: () => _addProduct(p),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: _border),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Cart', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      moneyFmtIdr(items.fold<int>(0, (s, i) => s + _lineTotal(i).toInt())),
                      style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Tap products to add', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          final product = _productById[item.productId];
                          final name = product?.name ?? 'Product ${item.productId}';
                          return ListTile(
                            dense: true,
                            title: Text(name, style: const TextStyle(color: _text, fontSize: 14)),
                            subtitle: Text(
                              '${moneyFmtIdr(item.price.toInt())} × ${item.qty}',
                              style: const TextStyle(color: _muted, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18, color: _muted),
                                  onPressed: () => _updateQty(i, item.qty - 1),
                                ),
                                Text('${item.qty}', style: const TextStyle(color: _text)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18, color: _accent),
                                  onPressed: () => _updateQty(i, item.qty + 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
