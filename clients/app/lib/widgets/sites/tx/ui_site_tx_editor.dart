import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_items.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/ui_receipt.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_tx_save_menu.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _bg = Color(0xFF08080A);

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
    setState(() => _tx = next);
    _refreshPreview();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction saved'), behavior: SnackBarBehavior.floating));
      if (_printReceipt) {
        await showPrintReceipt(context, saved, siteApi: widget.api, site: widget.site, productNames: _productNameMap());
      }
      if (!mounted) return;
      if (openNew) {
        setState(() => _tx = _txApi.newSale(widget.siteIid));
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
          UiTxSaveMenu(
            busy: _busy,
            canSave: _validate() == null,
            saveBlockReason: _validate(),
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
                SectionTxItems(items: _tx.items, products: _products, onChanged: _itemsChanged),
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
                Text(moneyFmtIdr(nominal.toInt()), style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Paid ${moneyFmtIdr(paid.toInt())}', style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Widget _paymentsTab(Int64 nominal, Int64 paid) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${moneyFmtIdr(nominal.toInt())}', style: const TextStyle(color: _text, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Paid: ${moneyFmtIdr(paid.toInt())}', style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 16),
            if (_tx.payments.isEmpty)
              const Text('No payments yet', style: TextStyle(color: _muted))
            else
              ..._tx.payments.map(
                (p) => ListTile(
                  dense: true,
                  title: Text(txPaymentMethodLabel(p.method), style: const TextStyle(color: _text)),
                  trailing: Text(moneyFmtIdr(p.amount.toInt()), style: const TextStyle(color: _text)),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: nominal <= Int64.ZERO ? null : () => _paymentAmountChanged(nominal),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Set cash payment to total'),
            ),
            if (paid != nominal && nominal > Int64.ZERO)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Remaining ${moneyFmtIdr((nominal - paid).toInt())}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                ),
              ),
          ],
        ),
      );

  Widget _ledgerTab<T>(String title, List<T> rows, String Function(T) label) => rows.isEmpty
      ? Center(child: Text('No $title lines yet', style: const TextStyle(color: _muted)))
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
          itemBuilder: (_, i) => Text(label(rows[i]), style: const TextStyle(color: _text, fontSize: 13)),
        );
}
