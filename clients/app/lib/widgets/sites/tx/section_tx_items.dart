import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_item_numpad.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_reserve_dialog.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class SectionTxItems extends StatefulWidget {
  const SectionTxItems({
    super.key,
    required this.items,
    required this.products,
    required this.onChanged,
    this.onCheckout,
  });

  final List<TxItem> items;
  final List<SiteProduct> products;
  final ValueChanged<List<TxItem>> onChanged;
  final VoidCallback? onCheckout;

  @override
  State<SectionTxItems> createState() => _SectionTxItemsState();
}

class _SectionTxItemsState extends State<SectionTxItems> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  var _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Map<Int64, SiteProduct> get _productById => {for (final p in widget.products) p.productId: p};

  Int64 _lineTotal(TxItem item) {
    var multiplier = 1;
    if (item.reservations.isNotEmpty) {
      multiplier = item.reservations.fold(0, (sum, r) => sum + (r.durationQty > 0 ? r.durationQty : 1));
      if (multiplier <= 0) multiplier = 1;
    }
    return Int64(item.qty) * item.price * Int64(multiplier);
  }

  void _addProduct(SiteProduct product) {
    final existingIndex = widget.items.indexWhere((i) => i.productId == product.productId);
    if (existingIndex >= 0) {
      final existing = widget.items[existingIndex];
      _updateQty(existingIndex, existing.qty + 1);
      return;
    }
    widget.onChanged([
      ...widget.items,
      TxItem(
        productId: product.productId,
        qty: 1,
        price: product.price > Int64.ZERO ? product.price : Int64.ZERO,
      ),
    ]);
  }

  void _updateQty(int index, int qty) {
    if (qty <= 0) {
      widget.onChanged([...widget.items]..removeAt(index));
      return;
    }
    widget.onChanged(
      widget.items.asMap().entries.map((e) => e.key == index ? (e.value.clone()..qty = qty) : e.value).toList(growable: false),
    );
  }

  Future<void> _editItem(int index) async {
    final item = widget.items[index];
    final product = _productById[item.productId];
    final updated = await showTransaksiItemNumpad(
      context: context,
      item: item,
      productName: product?.name ?? '',
    );
    if (updated != null && mounted) {
      if (updated.qty <= 0) {
        _updateQty(index, 0);
      } else {
        widget.onChanged(
          widget.items.asMap().entries.map((e) => e.key == index ? updated : e.value).toList(growable: false),
        );
      }
    }
  }

  Future<void> _editReservation(int index) async {
    final item = widget.items[index];
    final product = _productById[item.productId];
    final initialRes = item.reservations.isNotEmpty ? item.reservations.first : null;
    final res = await showTransaksiReserveDialog(
      context: context,
      productName: product?.name ?? 'Item',
      initial: initialRes,
    );
    if (res != null && mounted) {
      final updated = item.clone();
      updated.reservations.clear();
      updated.reservations.add(res);
      widget.onChanged(
        widget.items.asMap().entries.map((e) => e.key == index ? updated : e.value).toList(growable: false),
      );
    }
  }

  void _submitBarcode(String text) {
    final code = text.trim().toLowerCase();
    if (code.isEmpty) return;
    final matched = widget.products.where((p) => p.canSell && !p.isArchived).where((p) {
      return p.sku.toLowerCase() == code || p.productId.toString() == code || p.name.toLowerCase() == code;
    }).firstOrNull;

    if (matched != null) {
      _addProduct(matched);
      _searchCtrl.clear();
      _searchFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSellable = widget.products.where((p) => p.canSell && !p.isArchived).toList(growable: false);
    final categories = allSellable.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet().toList();

    var filtered = allSellable;
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category.trim() == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    }

    final totalCart = widget.items.fold<int>(0, (s, i) => s + _lineTotal(i).toInt());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Catalog & Quick Search
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Barcode Scan Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  style: const TextStyle(color: _text, fontSize: 13),
                  onSubmitted: _submitBarcode,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Cari produk / scan barcode (Enter)…',
                    hintStyle: const TextStyle(color: _muted, fontSize: 13),
                    prefixIcon: const Icon(Icons.qr_code_scanner_outlined, size: 18, color: _accent),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: _muted),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF141417),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                  ),
                ),
              ),

              // Category filter pills
              if (categories.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: _selectedCategory == null,
                          label: const Text('Semua', style: TextStyle(fontSize: 12)),
                          selectedColor: _accent,
                          backgroundColor: const Color(0xFF18181B),
                          side: BorderSide(color: _selectedCategory == null ? _accent : _border),
                          labelStyle: TextStyle(
                            color: _selectedCategory == null ? const Color(0xFF052E1B) : _text,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (s) => setState(() => _selectedCategory = null),
                        ),
                      ),
                      for (final cat in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: _selectedCategory == cat,
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selectedColor: _accent,
                            backgroundColor: const Color(0xFF18181B),
                            side: BorderSide(color: _selectedCategory == cat ? _accent : _border),
                            labelStyle: TextStyle(
                              color: _selectedCategory == cat ? const Color(0xFF052E1B) : _text,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (s) => setState(() => _selectedCategory = s ? cat : null),
                          ),
                        ),
                    ],
                  ),
                ),

              // Product Catalog List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Tidak ada produk yang cocok', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final inCart = widget.items.where((it) => it.productId == p.productId).firstOrNull;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(p.name, style: const TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w500)),
                                ),
                                if (p.canReserve)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Reservasi', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  p.price > Int64.ZERO ? moneyFmtIdr(p.price.toInt()) : 'Gratis',
                                  style: const TextStyle(color: _muted, fontSize: 12),
                                ),
                                if (p.trackStock) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stok: ${p.stockQty}',
                                    style: TextStyle(
                                      color: p.stockQty <= 5 ? Colors.orangeAccent : _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: inCart != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12)),
                                    child: Text('${inCart.qty}', style: const TextStyle(color: Color(0xFF052E1B), fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: _accent, size: 22),
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

        // Right Column: Cart & Direct Bayar Button
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Keranjang (Cart)', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '${widget.items.length} item',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Cart items list
              Expanded(
                child: widget.items.isEmpty
                    ? const Center(child: Text('Ketuk produk untuk menambahkan', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final item = widget.items[i];
                          final product = _productById[item.productId];
                          final name = product?.name ?? 'Item ${item.productId}';
                          final lineTotal = _lineTotal(item);
                          final hasRes = item.reservations.isNotEmpty;
                          final hasNote = item.note.trim().isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141417),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(name, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                  Text(
                                    moneyFmtIdr(lineTotal.toInt()),
                                    style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => _editItem(i),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${moneyFmtIdr(item.price.toInt())} × ${item.qty}',
                                            style: const TextStyle(color: _muted, fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit_note, size: 14, color: _accent),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (hasNote)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text('“${item.note}”', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic)),
                                    ),
                                  if (hasRes)
                                    InkWell(
                                      onTap: () => _editReservation(i),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.event_seat_outlined, size: 12, color: Colors.lightBlueAccent),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reservasi: ${item.reservations.first.durationQty} unit (${item.reservations.first.note.isNotEmpty ? item.reservations.first.note : "Terkonfirmasi"})',
                                              style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (product != null && product.canReserve && !hasRes)
                                    InkWell(
                                      onTap: () => _editReservation(i),
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text('+ Set Reservasi / Jadwal', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: _muted),
                                    onPressed: () => _updateQty(i, item.qty - 1),
                                  ),
                                  InkWell(
                                    onTap: () => _editItem(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F1F23),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('${item.qty}', style: const TextStyle(color: _text, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 18, color: _accent),
                                    onPressed: () => _updateQty(i, item.qty + 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Checkout Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF101013),
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(color: _muted, fontSize: 13)),
                        Text(
                          moneyFmtIdr(totalCart),
                          style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFF052E1B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: totalCart <= 0 || widget.onCheckout == null ? null : widget.onCheckout,
                      icon: const Icon(Icons.payments_outlined, size: 20),
                      label: Text(
                        'Bayar  •  ${moneyFmtIdr(totalCart)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
