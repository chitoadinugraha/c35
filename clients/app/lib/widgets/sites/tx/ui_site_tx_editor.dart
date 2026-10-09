import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_items.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:alienai_c35/c/site/site_commerce_media_prefetch.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_offline_queue.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_discount_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_parked_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_receipt_settings_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/payment/ask_transaksi_payment_method.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:alienai_c35/c/hardware/thermal_tx_print.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
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
    this.posEntry = false,
  });

  final int siteIid;
  final SiteApi api;
  final SiteRow? site;
  final Int64? txId;
  final ValueChanged<Tx>? onSaved;
  /// Full-screen POS route (Sites picker / hints), not nested under Orders tab.
  final bool posEntry;

  @override
  State<UiSiteTxEditor> createState() => _UiSiteTxEditorState();
}

class _UiSiteTxEditorState extends State<UiSiteTxEditor> with TickerProviderStateMixin {
  final _posItemsKey = GlobalKey<SectionTxItemsState>();
  late final TxApi _txApi = TxApi(widget.api.conn);
  TabController? _tabs;
  var _loading = true;
  var _busy = false;
  var _previewLoading = false;
  var _printReceipt = false;
  var _showTrackingQrOnReceipt = true;
  Object? _error;
  late Tx _tx;
  var _products = <SiteProduct>[];
  var _contacts = <SiteContact>[];
  var _catalogOffline = false;
  ResTxPreview? _preview;
  Timer? _previewDebounce;

  int get _editorTabCount => widget.posEntry ? 0 : (Session.instance.isRoot ? 4 : 2);

  @override
  void initState() {
    super.initState();
    _syncTabController();
    widget.api.conn.status.addListener(_onConnStatus);
    _load();
  }

  @override
  void dispose() {
    widget.api.conn.status.removeListener(_onConnStatus);
    _previewDebounce?.cancel();
    _tabs?.dispose();
    super.dispose();
  }

  void _onConnStatus() {
    if (widget.api.conn.status.value != ChatConnStatus.connected) return;
    unawaited(_syncOfflineQueue());
  }

  Future<void> _syncOfflineQueue() async {
    try {
      final n = await _txApi.syncOfflineQueue(widget.siteIid);
      if (n > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(n == 1 ? '1 penjualan offline tersinkron' : '$n penjualan offline tersinkron'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _syncTabController() {
    final n = _editorTabCount;
    if (n <= 0) {
      _tabs?.dispose();
      _tabs = null;
      return;
    }
    if (_tabs != null && _tabs!.length == n) return;
    _tabs?.dispose();
    _tabs = TabController(length: n, vsync: this);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _products = await widget.api.productList(widget.siteIid);
      unawaited(siteCommerceMediaPrefetch(products: _products, sitePic: widget.site?.pic));
      _contacts = await widget.api.contactList(widget.siteIid);
      if (widget.txId != null && widget.txId! > Int64.ZERO) {
        _tx = await _txApi.get(widget.siteIid, widget.txId!);
      } else {
        _tx = await _txApi.newSale(widget.siteIid);
      }
      await ThermalPrinterManager.instance.ensureLoaded();
      if (mounted) {
        _printReceipt = ThermalPrinterManager.instance.autoPrintReceipt;
      }
      try {
        final siteConfig = await widget.api.configGet(widget.siteIid);
        if (mounted) {
          _showTrackingQrOnReceipt = receiptShowQrLinkFromCapabilities(siteConfig.capabilitiesJson);
        }
      } catch (_) {}
      await _refreshPreview();
      _catalogOffline = widget.api.conn.status.value != ChatConnStatus.connected;
      if (widget.api.conn.status.value == ChatConnStatus.connected) {
        unawaited(_syncOfflineQueue());
      }
    } catch (e) {
      _error = e;
      _catalogOffline = false;
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
    if (widget.posEntry) return;
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) unawaited(_refreshPreview());
    });
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
      title: 'Tambah Diskon',
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
      final payload = _tx.clone();
      if (payload.timeTsMs <= Int64.ZERO) {
        payload.timeTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
      }
      receiptStampCashier(payload, Session.instance.name);
      final saved = await _txApi.putSale(widget.siteIid, payload);
      widget.onSaved?.call(saved);
      if (!mounted) return;
      if (saved.txId > Int64.ZERO) {
        final stillQueued = (await TxOfflineQueue.listPending(widget.siteIid)).any((t) => t.txId == saved.txId);
        if (stillQueued && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tersimpan offline — No. Nota tetap sama; akan disinkron saat online.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      final hasCash = saved.payments.any((p) => p.method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH) ||
          _tx.payments.any((p) => p.method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH);
      if (hasCash && ThermalPrinterManager.instance.autoKickDrawer) {
        ThermalPrinterManager.instance.kickCashDrawer();
      }

      if (widget.posEntry) {
        await showPosReceiptAfterSale(
          context,
          saved,
          siteApi: widget.api,
          site: widget.site,
          productNames: _productNameMap(),
          config: _receiptConfigOverride(),
        );
        if (!mounted) return;
        await _startNewSale();
        return;
      }

      if (_printReceipt) {
        final printerMgr = ThermalPrinterManager.instance;
        if (printerMgr.isRawEscPosConfigured) {
          final ok = await printTxToThermalPrinter(
            tx: saved,
            site: widget.site,
            productNames: _productNameMap(),
            config: _receiptConfigOverride(),
          );
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to print receipt to printer'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (printerMgr.usesRawEscPos) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Printer not configured — open Printer settings'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          await showPrintReceipt(
            context,
            saved,
            siteApi: widget.api,
            site: widget.site,
            productNames: _productNameMap(),
            config: _receiptConfigOverride(),
          );
        }
      }
      if (!mounted) return;
      if (openNew) {
        await _startNewSale();
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

  void _itemsChanged(List<TxItem> items) {
    final next = _tx.clone();
    if (_tx.txId <= Int64.ZERO) {
      if (_tx.items.isEmpty && items.isNotEmpty) {
        next.timeTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
      } else if (items.isEmpty) {
        next.timeTsMs = Int64.ZERO;
      }
    }
    next.items.clear();
    next.items.addAll(items);
    _txChanged(next);
  }

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

  Future<SiteContact?> _addCustomerFromPos(String name) async {
    try {
      final draft = widget.api.contactNew(widget.siteIid)..name = name;
      final saved = await widget.api.contactPut(widget.siteIid, draft);
      if (mounted) setState(() => _contacts = [..._contacts, saved]);
      return saved;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      return null;
    }
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

  Future<void> _printUnpaidReceipt() async {
    if (_tx.items.isEmpty) return;
    final preview = _tx.clone();
    receiptStampCashier(preview, Session.instance.name);
    await showNotaPage(
      context,
      preview,
      siteApi: widget.api,
      site: widget.site,
      productNames: _productNameMap(),
      config: _receiptConfigOverride(),
      doneLabel: 'Tutup',
    );
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

  ReceiptConfig _receiptConfigOverride() => ReceiptConfig(showQrLink: _showTrackingQrOnReceipt);

  Future<void> _openReceiptSettings() async {
    try {
      final siteConfig = await widget.api.configGet(widget.siteIid);
      if (!mounted) return;
      final saved = await showTransaksiReceiptSettingsDialog(
        context: context,
        siteApi: widget.api,
        siteIid: widget.siteIid,
        site: widget.site,
        capabilitiesJson: siteConfig.capabilitiesJson,
      );
      if (saved != true || !mounted) return;
      final updated = await widget.api.configGet(widget.siteIid);
      setState(() {
        _showTrackingQrOnReceipt = receiptShowQrLinkFromCapabilities(updated.capabilitiesJson);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _viewReceipt() => showViewReceipt(
        context,
        txEnsureCashPayment(_tx),
        siteApi: widget.api,
        site: widget.site,
        productNames: _productNameMap(),
        config: _receiptConfigOverride(),
      );

  Future<void> _startNewSale() async {
    final tx = await _txApi.newSale(widget.siteIid);
    if (!mounted) return;
    setState(() {
      _tx = tx;
      _printReceipt = ThermalPrinterManager.instance.autoPrintReceipt;
    });
  }

  Future<void> _holdOrder() async {
    if (_tx.items.isEmpty) return;
    if (_tx.timeTsMs <= Int64.ZERO) {
      _tx.timeTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
    }
    await TxOfflineQueue.txEnsureClientTxId(_tx);
    final parked = TxParkedOrders.instance.add(widget.siteIid, _tx);
    await _startNewSale();
    await _refreshPreview();
    if (mounted) {
      final customer = parkedTxCustomerLabel(parked.tx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Held $customer · ${parked.note}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openParkedOrders() async {
    final recalled = await showTransaksiParkedDialog(
      context: context,
      siteIid: widget.siteIid,
      products: _products,
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
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _text,
          automaticallyImplyLeading: !widget.posEntry,
          leading: widget.posEntry
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close POS',
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(uiFriendlyError(_error!), textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final nominal = txItemsNominal(_tx);
    final paid = txPaymentsTotal(_tx);
    final previewTx = _preview?.tx ?? txEnsureCashPayment(_tx);
    final appBarTitle = widget.posEntry
        ? (widget.site?.name.isNotEmpty == true ? widget.site!.name : 'POS')
        : (_tx.txId > Int64.ZERO ? 'Order ${_tx.txId}' : 'New sale');
    final tabLabels = widget.posEntry
        ? const <Tab>[]
        : Session.instance.isRoot
            ? const [Tab(text: 'Items'), Tab(text: 'Payments'), Tab(text: 'Acc'), Tab(text: 'Stock')]
            : const [Tab(text: 'Items'), Tab(text: 'Payments')];
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compactPosCart = widget.posEntry && !posTxShowsInlineCartForWidth(layoutW, posShell: true);
        return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: Text(appBarTitle),
        automaticallyImplyLeading: !widget.posEntry,
        leading: widget.posEntry
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close POS',
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          if (compactPosCart)
            Builder(
              builder: (context) {
                final cartQty = _tx.items.fold<int>(0, (sum, item) => sum + item.qty);
                return IconButton(
                  tooltip: cartQty > 0 ? 'Keranjang ($cartQty)' : 'Keranjang',
                  onPressed: () => _posItemsKey.currentState?.openCartDrawer(),
                  icon: Badge.count(
                    count: cartQty,
                    isLabelVisible: cartQty > 0,
                    backgroundColor: _accent,
                    textColor: const Color(0xFF052E1B),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                );
              },
            ),
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
            posShell: widget.posEntry,
            busy: _busy,
            canSave: _validate() == null,
            saveBlockReason: _validate(),
            canHold: _tx.items.isNotEmpty,
            onHold: _tx.items.isNotEmpty ? _holdOrder : null,
            printReceipt: _printReceipt,
            onPrintReceiptChanged: (v) => setState(() => _printReceipt = v),
            onReceiptSettings: _openReceiptSettings,
            onViewReceipt: _viewReceipt,
            onSave: () => _save(),
            onSaveNew: () => _save(openNew: true),
          ),
          const SizedBox(width: 8),
        ],
        bottom: _tabs != null && tabLabels.isNotEmpty
            ? TabBar(
                controller: _tabs,
                labelColor: _text,
                unselectedLabelColor: _muted,
                indicatorColor: const Color(0xFF34D399),
                dividerColor: _border,
                tabs: tabLabels,
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_catalogOffline) _offlineBanner(),
          if (!widget.posEntry) _headerBar(nominal, paid),
          Expanded(child: widget.posEntry ? _itemsSection() : _tabbedBody(previewTx, nominal, paid)),
          if (_previewLoading && !widget.posEntry) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF34D399)),
        ],
      ),
    );
      },
    );
  }

  Widget _offlineBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: const Color(0xFF422006),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 16, color: Color(0xFFFBBF24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline — katalog dari cache. Penjualan disimpan lokal (tx id tetap) dan disinkron saat online.',
                style: TextStyle(color: Color(0xFFFDE68A), fontSize: 12),
              ),
            ),
          ],
        ),
      );

  Widget _itemsSection() => SectionTxItems(
        key: widget.posEntry ? _posItemsKey : null,
        items: _tx.items,
        products: _products,
        onChanged: _itemsChanged,
        onCheckout: _checkoutTap,
        discounts: _tx.discounts,
        onDiscountsChanged: _discountsChanged,
        posShell: widget.posEntry,
        contacts: widget.posEntry ? _contacts : const [],
        selectedContact: widget.posEntry ? _selectedContact() : null,
        onContactChanged: widget.posEntry ? _contactChanged : null,
        onAddCustomer: widget.posEntry ? _addCustomerFromPos : null,
        payments: widget.posEntry ? _tx.payments : const [],
        onRemovePayment: widget.posEntry ? _removePayment : null,
        onCartDiscount: widget.posEntry ? _openCartDiscountDialog : null,
        onPrintUnpaidReceipt: widget.posEntry ? _printUnpaidReceipt : null,
      );

  Widget _tabbedBody(Tx previewTx, Int64 nominal, Int64 paid) => TabBarView(
        controller: _tabs!,
        children: [
          _itemsSection(),
          _paymentsTab(nominal, paid),
          if (Session.instance.isRoot) ...[
            _ledgerTab('Accounting', previewTx.accs, (a) => '${a.accCode} ${a.note} ${moneyFmtIdr(a.amount.toInt())}'),
            _ledgerTab('Stock', previewTx.stocks, (s) => '${s.productId} qty ${s.qty} ${s.note}'),
          ],
        ],
      );

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
                remaining <= 0 ? 'Lunas' : 'Belum Dibayar',
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
