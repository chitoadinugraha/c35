import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_discount_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_item_numpad.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_reserve_dialog.dart';
import 'package:alienai_c35/widgets/io/in_site_contact.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_cart_pay.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_product_thumb.dart';
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
    this.discounts = const [],
    this.onDiscountsChanged,
    this.posShell = false,
    this.contacts = const [],
    this.selectedContact,
    this.onContactChanged,
    this.onAddCustomer,
    this.payments = const [],
    this.onRemovePayment,
    this.onCartDiscount,
    this.onPrintUnpaidReceipt,
  });

  final List<TxItem> items;
  final List<SiteProduct> products;
  final ValueChanged<List<TxItem>> onChanged;
  final VoidCallback? onCheckout;
  final List<TxDiscount> discounts;
  final ValueChanged<List<TxDiscount>>? onDiscountsChanged;
  final bool posShell;
  final List<SiteContact> contacts;
  final SiteContact? selectedContact;
  final ValueChanged<SiteContact?>? onContactChanged;
  final Future<SiteContact?> Function(String name)? onAddCustomer;
  final List<TxPayment> payments;
  final ValueChanged<int>? onRemovePayment;
  final VoidCallback? onCartDiscount;
  final VoidCallback? onPrintUnpaidReceipt;

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

  int _cartLineIndexForMerge(Int64 productId, String note, {int? exceptIndex}) {
    final key = note.trim();
    for (var i = 0; i < widget.items.length; i++) {
      if (exceptIndex != null && i == exceptIndex) continue;
      final line = widget.items[i];
      if (line.productId == productId && line.note.trim() == key) return i;
    }
    return -1;
  }

  int _productQtyInCart(Int64 productId) =>
      widget.items.where((i) => i.productId == productId).fold(0, (sum, i) => sum + i.qty);

  void _applyLineTotals(TxItem item) {
    final gross = txItemLineNominal(item);
    if (item.totalDiscount > gross) {
      item.totalDiscount = gross;
    }
    item.totalPrice = gross;
    item.totalNet = txItemLineNet(item);
  }

  void _addProduct(SiteProduct product) {
    final existingIndex = _cartLineIndexForMerge(product.productId, '');
    if (existingIndex >= 0) {
      final existing = widget.items[existingIndex];
      _updateQty(existingIndex, existing.qty + 1);
      return;
    }
    final price = product.price > Int64.ZERO ? product.price : Int64.ZERO;
    final item = TxItem(
      productId: product.productId,
      qty: 1,
      price: price,
      totalPrice: price,
      totalNet: price,
    );
    widget.onChanged([
      ...widget.items,
      item,
    ]);
  }

  void _updateQty(int index, int qty) {
    if (qty <= 0) {
      widget.onChanged([...widget.items]..removeAt(index));
      return;
    }
    widget.onChanged(
      widget.items.asMap().entries.map((e) {
        if (e.key == index) {
          final updated = e.value.clone()..qty = qty;
          final gross = txItemLineNominal(updated);
          if (updated.totalDiscount > gross) {
            updated.totalDiscount = gross;
          }
          updated.totalPrice = gross;
          updated.totalNet = txItemLineNet(updated);
          return updated;
        }
        return e.value;
      }).toList(growable: false),
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
        final noteKey = updated.note.trim();
        final mergeIndex = _cartLineIndexForMerge(updated.productId, noteKey, exceptIndex: index);
        if (mergeIndex >= 0) {
          final target = widget.items[mergeIndex].clone();
          target.qty += updated.qty;
          _applyLineTotals(target);
          final next = <TxItem>[];
          for (var i = 0; i < widget.items.length; i++) {
            if (i == index) continue;
            next.add(i == mergeIndex ? target : widget.items[i]);
          }
          widget.onChanged(next);
        } else {
          final line = updated.clone();
          _applyLineTotals(line);
          widget.onChanged(
            widget.items.asMap().entries.map((e) => e.key == index ? line : e.value).toList(growable: false),
          );
        }
      }
    }
  }

  Future<void> _editItemDiscount(int index) async {
    final item = widget.items[index];
    final product = _productById[item.productId];
    final originalAmount = txItemLineNominal(item);
    if (originalAmount <= Int64.ZERO) return;

    final initialDiscount = item.totalDiscount > Int64.ZERO
        ? TxDiscount(
            discountType: 'fixed',
            amount: item.totalDiscount,
          )
        : null;

    final discount = await showTransaksiDiscountDialog(
      context: context,
      originalAmount: originalAmount,
      initialDiscount: initialDiscount,
      title: 'Diskon ${product?.name ?? "Item"}',
    );

    if (discount != null && mounted) {
      final updated = item.clone();
      if (discount.amount <= Int64.ZERO) {
        updated.totalDiscount = Int64.ZERO;
        updated.totalNet = txItemLineNominal(updated);
      } else {
        updated.totalDiscount = discount.amount;
        updated.totalNet = txItemLineNet(updated);
      }
      widget.onChanged(
        widget.items.asMap().entries.map((e) => e.key == index ? updated : e.value).toList(growable: false),
      );
    }
  }

  Future<void> _editCartDiscount() async {
    if (widget.onDiscountsChanged == null) return;
    final itemsSubtotal = widget.items.fold(Int64.ZERO, (s, i) => s + txItemLineNet(i));
    if (itemsSubtotal <= Int64.ZERO) return;

    final initialDiscount = widget.discounts.isNotEmpty ? widget.discounts.first : null;
    final discount = await showTransaksiDiscountDialog(
      context: context,
      originalAmount: itemsSubtotal,
      initialDiscount: initialDiscount,
      title: 'Tambah Diskon',
    );

    if (discount != null && mounted) {
      if (discount.amount <= Int64.ZERO) {
        widget.onDiscountsChanged!(const []);
      } else {
        widget.onDiscountsChanged!([discount]);
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

  Widget _cartLine(int index) {
    final item = widget.items[index];
    final product = _productById[item.productId];
    final name = product?.name ?? 'Item ${item.productId}';
    final lineGross = txItemLineNominal(item);
    final lineDisc = txItemDiscountNominal(item);
    final lineNet = txItemLineNet(item);
    final hasRes = item.reservations.isNotEmpty;
    final hasNote = item.note.trim().isNotEmpty;
    final hasDisc = lineDisc > Int64.ZERO;
    final lineTotal = hasDisc ? lineNet : lineGross;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _editItem(index),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (product != null) ...[
                UiSiteProductThumb(product: product, size: 36),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${item.qty} × ${moneyFmtIdr(item.price.toInt())}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    if (hasDisc || hasNote || hasRes || (product != null && product.canReserve && !hasRes))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (hasDisc)
                              InkWell(
                                onTap: () => _editItemDiscount(index),
                                child: Text('-${moneyFmtIdr(lineDisc.toInt())}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            if (hasNote) Text('“${item.note}”', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                            if (hasRes)
                              InkWell(
                                onTap: () => _editReservation(index),
                                child: const Text('Reservasi', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11)),
                              )
                            else if (product != null && product.canReserve)
                              InkWell(
                                onTap: () => _editReservation(index),
                                child: const Text('+ Reservasi', style: TextStyle(color: _accent, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDisc)
                    Text(
                      moneyFmtIdr(lineGross.toInt()),
                      style: const TextStyle(color: _muted, fontSize: 11, decoration: TextDecoration.lineThrough),
                    ),
                  Text(
                    moneyFmtIdr(lineTotal.toInt()),
                    style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  void _submitBarcode(String text) {
    final code = text.trim().toLowerCase();
    if (code.isEmpty) return;
    final matched = widget.products.where((p) => p.canSell && !p.isArchived).where((p) {
      final barcodes = siteProductBarcodesRead(p).map((b) => b.toLowerCase());
      return p.sku.toLowerCase() == code ||
          barcodes.contains(code) ||
          p.productId.toString() == code ||
          p.name.toLowerCase() == code;
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

    final grossSubtotal = widget.items.fold(Int64.ZERO, (s, i) => s + txItemLineNominal(i));
    final itemsDiscountTotal = widget.items.fold(Int64.ZERO, (s, i) => s + txItemDiscountNominal(i));
    final itemsNetTotal = widget.items.fold(Int64.ZERO, (s, i) => s + txItemLineNet(i));
    final cartDiscountTotal = widget.discounts.fold(Int64.ZERO, (s, d) => s + (d.amount > Int64.ZERO ? d.amount : Int64.ZERO));
    final finalTotal = (itemsNetTotal - cartDiscountTotal) > Int64.ZERO
        ? (itemsNetTotal - cartDiscountTotal)
        : Int64.ZERO;

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
                          final inCartQty = _productQtyInCart(p.productId);
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: UiSiteProductThumb(product: p, size: 44),
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
                                if (inCartQty > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '· $inCartQty in cart',
                                    style: TextStyle(color: _accent.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
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
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: _muted, size: 22),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('Keranjang', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${widget.items.length} item', style: const TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                    if (widget.posShell && widget.onContactChanged != null) ...[
                      const SizedBox(height: 6),
                      InSiteContact(
                        value: widget.selectedContact == null ? '' : '${widget.selectedContact!.contactId}',
                        contacts: {for (final c in widget.contacts) '${c.contactId}': c},
                        onAddCustomer: widget.onAddCustomer == null
                            ? null
                            : (name) async {
                                final c = await widget.onAddCustomer!(name);
                                if (c != null) widget.onContactChanged!(c);
                                return c == null ? null : '${c.contactId}';
                              },
                        onCommit: (id) async {
                          if (id.isEmpty) {
                            widget.onContactChanged!(null);
                            return;
                          }
                          final picked = widget.contacts.where((c) => '${c.contactId}' == id).firstOrNull;
                          if (picked != null) widget.onContactChanged!(picked);
                        },
                      ),
                    ],
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
                        itemBuilder: (_, i) => _cartLine(i),
                      ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF101013),
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: widget.posShell
                    ? SectionTxCartPay(
                        grossSubtotal: grossSubtotal,
                        itemsDiscountTotal: itemsDiscountTotal,
                        cartDiscountTotal: cartDiscountTotal,
                        finalTotal: finalTotal,
                        paid: widget.payments.fold(Int64.ZERO, (s, p) => s + p.amount),
                        payments: widget.payments,
                        onCartDiscount: widget.items.isEmpty ? null : (widget.onCartDiscount ?? _editCartDiscount),
                        onRemovePayment: widget.onRemovePayment ?? (_) {},
                        onCheckout: widget.items.isEmpty ? null : widget.onCheckout,
                        onPrintUnpaid: widget.items.isEmpty ? null : widget.onPrintUnpaidReceipt,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal Produk', style: TextStyle(color: _muted, fontSize: 12)),
                              Text(moneyFmtIdr(grossSubtotal.toInt()), style: const TextStyle(color: _text, fontSize: 12)),
                            ],
                          ),
                          if (itemsDiscountTotal > Int64.ZERO) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Diskon Produk', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                Text(
                                  '- ${moneyFmtIdr(itemsDiscountTotal.toInt())}',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: widget.items.isEmpty ? null : _editCartDiscount,
                                child: Text(
                                  cartDiscountTotal > Int64.ZERO ? 'Diskon Transaksi' : 'Tambah Diskon',
                                  style: TextStyle(
                                    color: cartDiscountTotal > Int64.ZERO ? Colors.redAccent : _accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                cartDiscountTotal > Int64.ZERO ? '- ${moneyFmtIdr(cartDiscountTotal.toInt())}' : 'Rp 0',
                                style: TextStyle(color: cartDiscountTotal > Int64.ZERO ? Colors.redAccent : _muted, fontSize: 12),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: _border)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(color: _muted, fontSize: 13)),
                              Text(
                                moneyFmtIdr(finalTotal.toInt()),
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
                            onPressed: finalTotal < Int64.ZERO || widget.items.isEmpty || widget.onCheckout == null ? null : widget.onCheckout,
                            icon: const Icon(Icons.payments_outlined, size: 20),
                            label: Text('Bayar  •  ${moneyFmtIdr(finalTotal.toInt())}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
