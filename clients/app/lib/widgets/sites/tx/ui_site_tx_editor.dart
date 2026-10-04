import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_items.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_discount_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_parked_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/payment/ask_transaksi_payment_method.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/esc_pos_receipt_formatter.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/ui_receipt.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_parked_orders.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_tx_save_menu.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _bg = Color(0xFF08080A);
const _accent = Color(0xFF34D399);

class UiSiteTxEditor extends StatefulWidget {
  const UiSiteTxEditor({
    super.key,
    required this.siteIid,
    required this.api,
    this.site,
    this.txId,
    this.onSaved,
  });

  final int siteIid;
  final SiteApi api;
  final SiteRow? site;
  final Int64? txId;
  final ValueChanged<Tx>? onSaved;

  @override
  State<UiSiteTxEditor> createState() => _UiSiteTxEditorState();
}

class _UiSiteTxEditorState extends State<UiSiteTxEditor> with SingleTickerProviderStateMixin {
  late final TxApi _txApi = TxApi(widget.api.conn);
  late TabController _tabs;
  var _loading = true;
  var _busy = false;
  var _previewLoading = false;
  var _printReceipt = false;
  Object? _error;
  late Tx _tx;
  var _products = <SiteProduct>[];
  var _contacts = <SiteContact>[];
  ResTxPreview? _preview;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _products = await widget.api.productList(widget.siteIid);
      _contacts = await widget.api.contactList(widget.siteIid);
      if (widget.txId != null && widget.txId! > Int64.ZERO) {
        _tx = await _txApi.get(widget.siteIid, widget.txId!);
      } else {
        _tx = _txApi.newSale(widget.siteIid);
      }
      await ThermalPrinterManager.instance.ensureLoaded();
      if (mounted) {
        _printReceipt = ThermalPrinterManager.instance.autoPrintReceipt;
      }
      await _refreshPreview();
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshPreview() async {
    if (_tx.items.isEmpty) {
      setState(() => _preview = null);
      return;
    }
    setState(() => _previewLoading = true);
    try {
      final res = await _txApi.preview(txEnsureCashPayment(_tx));
      if (mounted) setState(() => _preview = res);
    } catch (_) {
      if (mounted) setState(() => _preview = null);
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  void _txChanged(Tx next) {
    for (final item in next.items) {
      item.totalPrice = txItemLineNominal(item);
      item.totalDiscount = txItemDiscountNominal(item);
      item.totalNet = txItemLineNet(item);
    }
    next.totalDiscounts = txTotalDiscounts(next);
    next.total = txItemsNominal(next);
    setState(() => _tx = next);
    _refreshPreview();
  }

  void _discountsChanged(List<TxDiscount> discounts) {
    final next = _tx.clone();
    next.discounts.clear();
    next.discounts.addAll(discounts);
    _txChanged(next);
  }

  Future<void> _openCartDiscountDialog() async {
    final subtotal = _tx.items.fold(Int64.ZERO, (s, i) => s + txItemLineNet(i));
    if (subtotal <= Int64.ZERO) return;
    final initial = _tx.discounts.isNotEmpty ? _tx.discounts.first : null;
    final discount = await showTransaksiDiscountDialog(
      context: context,
      originalAmount: subtotal,
      initialDiscount: initial,
      title: 'Diskon Transaksi (Nota)',
    );
    if (discount != null && mounted) {
      if (discount.amount <= Int64.ZERO) {
        _discountsChanged(const []);
      } else {
        _discountsChanged([discount]);
      }
    }
  }

  String? _validate() => txValidateSale(txEnsureCashPayment(_tx));

  Future<void> _save({bool openNew = false}) async {
    if (_busy) return;
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await _txApi.putSale(widget.siteIid, _tx);
      widget.onSaved?.call(saved);
      if (!mounted) return;
      final hasCash = saved.payments.any((p) => p.method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH) ||
          _tx.payments.any((p) => p.method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH);
      if (hasCash && ThermalPrinterManager.instance.autoKickDrawer) {
        ThermalPrinterManager.instance.kickCashDrawer();
      }

      if (_printReceipt) {
        final printerMgr = ThermalPrinterManager.instance;
        if (printerMgr.printerType == ThermalPrinterType.network) {
          final bytes = EscPosReceiptFormatter.formatReceipt(
            saved,
            site: widget.site,
            productNames: _productNameMap(),
            paperWidth: printerMgr.paperWidth,
          );
          final ok = await printerMgr.printRaw(bytes);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to print receipt to network printer'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          await showPrintReceipt(context, saved, siteApi: widget.api, site: widget.site, productNames: _productNameMap());
        }
      }
      if (!mounted) return;
      if (openNew) {
        setState(() {
          _tx = _txApi.newSale(widget.siteIid);
          _printReceipt = ThermalPrinterManager.instance.autoPrintReceipt;
        });
        await _refreshPreview();
      } else {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _itemsChanged(List<TxItem> items) => _txChanged(_tx.clone()..items.clear()..items.addAll(items));

  void _contactChanged(SiteContact? contact) {
    final next = _tx.clone();
    if (contact == null) {
      next.subjectContactId = Int64.ZERO;
      next.subjectName = '';
    } else {
      next.subjectContactId = contact.contactId;
      next.subjectName = contact.name;
      next.subjectPhone = contact.phone;
      next.subjectAddress = contact.address;
    }
    _txChanged(next);
  }

  void _paymentAmountChanged(Int64 amount) {
    final next = _tx.clone();
    next.payments.clear();
    if (amount > Int64.ZERO) {
      next.payments.add(TxPayment(
        method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
        amount: amount,
        tsMs: next.timeTsMs > Int64.ZERO ? next.timeTsMs : Int64(DateTime.now().millisecondsSinceEpoch),
      ));
    }
    _txChanged(next);
  }

  Future<void> _addPayment() async {
    final nominal = txItemsNominal(_tx);
    final paid = txPaymentsTotal(_tx);
    final remaining = (nominal - paid).toInt();
    if (remaining <= 0) return;
    final payment = await askTransaksiPaymentMethod(context: context, totalDue: remaining);
    if (payment != null && mounted) {
      final next = _tx.clone();
      next.payments.add(payment);
      _txChanged(next);
    }
  }

  void _removePayment(int index) {
    if (index >= 0 && index < _tx.payments.length) {
      final next = _tx.clone();
      next.payments.removeAt(index);
      _txChanged(next);
    }
  }

  Future<void> _checkoutTap() async {
    final nominal = txItemsNominal(_tx);
    final paid = txPaymentsTotal(_tx);
    final remaining = (nominal - paid).toInt();
    if (remaining > 0) {
      final payment = await askTransaksiPaymentMethod(context: context, totalDue: remaining);
      if (payment != null && mounted) {
        final next = _tx.clone();
        next.payments.add(payment);
        _txChanged(next);
        if (txPaymentsTotal(next) >= txItemsNominal(next)) {
          await _save();
        }
      }
    } else {
      await _save();
    }
  }

  SiteContact? _selectedContact() =>
      _contacts.where((c) => c.contactId == _tx.subjectContactId).firstOrNull;

  Map<String, String> _productNameMap() => {
        for (final p in _products) p.productId.toString(): p.name,
      };

  void _viewReceipt() => showViewReceipt(
        context,
        txEnsureCashPayment(_tx),
        siteApi: widget.api,
        site: widget.site,
        productNames: _productNameMap(),
      );

  Future<void> _holdOrder() async {
    if (_tx.items.isEmpty) return;
    final count = TxParkedOrders.instance.count(widget.siteIid);
    final defaultNote = 'Order #${count + 1}';
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Hold Order', style: TextStyle(color: _text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hold current cart to serve another customer.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              autofocus: true,
              style: const TextStyle(color: _text),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: const TextStyle(color: _muted),
                hintText: defaultNote,
                hintStyle: TextStyle(color: _muted.withValues(alpha: 0.6)),
                filled: true,
                fillColor: const Color(0xFF27272A).withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
              onSubmitted: (val) =>
                  Navigator.of(ctx).pop(val.trim().isNotEmpty ? val.trim() : defaultNote),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () {
              final text = noteCtrl.text.trim();
              Navigator.of(ctx).pop(text.isNotEmpty ? text : defaultNote);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
            ),
            child: const Text('Hold'),
          ),
        ],
      ),
    );
    if (note == null || !mounted) return;

    TxParkedOrders.instance.add(widget.siteIid, _tx, note: note);
    setState(() {
      _tx = _txApi.newSale(widget.siteIid);
    });
    await _refreshPreview();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order "$note" held'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openParkedOrders() async {
    final recalled = await showTransaksiParkedDialog(
      context: context,
      siteIid: widget.siteIid,
    );
    if (recalled == null || !mounted) return;

    if (_tx.items.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
          title: const Text('Replace current cart?', style: TextStyle(color: _text)),
          content: Text(
            'Your current cart has ${_tx.items.length} item(s). Recalling "${recalled.note}" will replace the current cart.',
            style: const TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Replace'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        TxParkedOrders.instance.restore(widget.siteIid, recalled);
        return;
      }
    }

    setState(() {
      _tx = recalled.tx.clone();
    });
    await _refreshPreview();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recalled order: ${recalled.note}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(backgroundColor: _bg, foregroundColor: _text),
        body: Center(child: Text(uiFriendlyError(_error!), style: const TextStyle(color: _muted))),
      );
    }
    final nominal = txItemsNominal(_tx);
    final paid = txPaymentsTotal(_tx);
    final previewTx = _preview?.tx ?? txEnsureCashPayment(_tx);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: Text(_tx.txId > Int64.ZERO ? 'Order ${_tx.txId}' : 'New sale'),
        actions: [
          ListenableBuilder(
            listenable: TxParkedOrders.instance,
            builder: (context, _) {
              final count = TxParkedOrders.instance.count(widget.siteIid);
              return IconButton(
                tooltip: count > 0 ? 'Parked orders ($count)' : 'Parked orders',
                icon: Badge.count(
                  count: count,
                  isLabelVisible: count > 0,
                  backgroundColor: const Color(0xFFF59E0B),
                  textColor: Colors.black,
                  child: const Icon(Icons.pause_circle_outline),
                ),
                onPressed: _openParkedOrders,
              );
            },
          ),
          const SizedBox(width: 4),
          UiTxSaveMenu(
            busy: _busy,
            canSave: _validate() == null,
            saveBlockReason: _validate(),
            canHold: _tx.items.isNotEmpty,
            onHold: _tx.items.isNotEmpty ? _holdOrder : null,
            printReceipt: _printReceipt,
            onPrintReceiptChanged: (v) => setState(() => _printReceipt = v),
            onViewReceipt: _viewReceipt,
            onSave: () => _save(),
            onSaveNew: () => _save(openNew: true),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _text,
          unselectedLabelColor: _muted,
          indicatorColor: const Color(0xFF34D399),
          dividerColor: _border,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Payments'),
            Tab(text: 'Acc'),
            Tab(text: 'Stock'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerBar(nominal, paid),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                SectionTxItems(
                  items: _tx.items,
                  products: _products,
                  onChanged: _itemsChanged,
                  onCheckout: _checkoutTap,
                  discounts: _tx.discounts,
                  onDiscountsChanged: _discountsChanged,
                ),
                _paymentsTab(nominal, paid),
                _ledgerTab('Accounting', previewTx.accs, (a) => '${a.accCode} ${a.note} ${moneyFmtIdr(a.amount.toInt())}'),
                _ledgerTab('Stock', previewTx.stocks, (s) => '${s.productId} qty ${s.qty} ${s.note}'),
              ],
            ),
          ),
          if (_previewLoading) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF34D399)),
        ],
      ),
    );
  }

  Widget _headerBar(Int64 nominal, Int64 paid) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SiteContact?>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF18181B),
                  value: _selectedContact(),
                  hint: const Text('Contact (optional)', style: TextStyle(color: _muted, fontSize: 13)),
                  items: [
                    const DropdownMenuItem<SiteContact?>(value: null, child: Text('No contact', style: TextStyle(color: _text))),
                    ..._contacts.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: _text)))),
                  ],
                  onChanged: _contactChanged,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (txTotalDiscounts(_tx) > Int64.ZERO) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moneyFmtIdr(txItemsGrossNominal(_tx).toInt()),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '-${moneyFmtIdr(txTotalDiscounts(_tx).toInt())}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
                Text(moneyFmtIdr(nominal.toInt()), style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Paid ${moneyFmtIdr(paid.toInt())}', style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Widget _paymentsTab(Int64 nominal, Int64 paid) {
    final remaining = nominal - paid;
    final gross = txItemsGrossNominal(_tx);
    final totalDisc = txTotalDiscounts(_tx);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard('Subtotal', moneyFmtIdr(gross.toInt()), _text),
            ),
            if (totalDisc > Int64.ZERO) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('Total Diskon', '- ${moneyFmtIdr(totalDisc.toInt())}', Colors.redAccent),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Total Tagihan', moneyFmtIdr(nominal.toInt()), _accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Sudah Dibayar', moneyFmtIdr(paid.toInt()), _text),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                remaining <= 0 ? 'Lunas' : 'Sisa Tagihan',
                remaining <= 0 ? 'Rp 0' : moneyFmtIdr(remaining.toInt()),
                remaining <= 0 ? _accent : Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF052E1B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: remaining <= 0 ? null : _addPayment,
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('Terima Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border),
                foregroundColor: _text,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: nominal <= Int64.ZERO ? null : () => _paymentAmountChanged(nominal),
              icon: const Icon(Icons.payments_outlined, size: 18, color: _muted),
              label: const Text('Uang Pas (Tunai)'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border),
                foregroundColor: _text,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openCartDiscountDialog,
              icon: const Icon(Icons.local_offer_outlined, size: 18, color: Colors.orangeAccent),
              label: Text(_tx.discounts.isNotEmpty ? 'Edit Diskon' : '+ Diskon'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Daftar Pembayaran', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_tx.payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141417),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: Text('Belum ada pembayaran ditambahkan', style: TextStyle(color: _muted, fontSize: 13)),
            ),
          )
        else
          for (var i = 0; i < _tx.payments.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(_paymentIcon(_tx.payments[i].method), color: _accent, size: 22),
                title: Text(txPaymentMethodLabel(_tx.payments[i].method), style: const TextStyle(color: _text, fontWeight: FontWeight.w600)),
                subtitle: _tx.payments[i].note.isNotEmpty ? Text(_tx.payments[i].note, style: const TextStyle(color: _muted, fontSize: 11)) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moneyFmtIdr(_tx.payments[i].amount.toInt()),
                      style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => _removePayment(i),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }

  Widget _statCard(String label, String value, Color valColor) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valColor, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  IconData _paymentIcon(TxPaymentMethod method) => switch (method) {
        TxPaymentMethod.TX_PAYMENT_METHOD_CASH => Icons.payments_outlined,
        TxPaymentMethod.TX_PAYMENT_METHOD_QRIS => Icons.qr_code_2_outlined,
        TxPaymentMethod.TX_PAYMENT_METHOD_TRANSFER => Icons.account_balance_outlined,
        TxPaymentMethod.TX_PAYMENT_METHOD_CARD => Icons.credit_card_outlined,
        TxPaymentMethod.TX_PAYMENT_METHOD_DEBT => Icons.assignment_late_outlined,
        _ => Icons.payment_outlined,
      };

  Widget _ledgerTab<T>(String title, List<T> rows, String Function(T) label) => rows.isEmpty
      ? Center(child: Text('No $title lines yet', style: const TextStyle(color: _muted)))
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
          itemBuilder: (_, i) => Text(label(rows[i]), style: const TextStyle(color: _text, fontSize: 13)),
        );
}
