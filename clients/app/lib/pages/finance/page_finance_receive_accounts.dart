import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/finance_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class PageFinanceReceiveAccounts extends StatefulWidget {
  const PageFinanceReceiveAccounts({super.key, required this.conn});

  final ReferralConn conn;

  @override
  State<PageFinanceReceiveAccounts> createState() => _PageFinanceReceiveAccountsState();
}

class _PageFinanceReceiveAccountsState extends State<PageFinanceReceiveAccounts> {
  static const _bg = Color(0xFF08080A);
  static const _card = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);

  var _loading = true;
  String? _error;
  List<BillingReceiveAccount> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await financeReceiveAccountList(widget.conn, activeOnly: false);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiFriendlyError(e, fallback: 'Could not load payment accounts.');
      });
    }
  }

  Future<void> _editAccount([BillingReceiveAccount? existing]) async {
    final bankCtrl = TextEditingController(text: existing?.bankId ?? 'BCA');
    final acctCtrl = TextEditingController(text: existing?.accountNumber ?? '');
    final nameCtrl = TextEditingController(text: existing?.accountName ?? '');
    final currencyCtrl = TextEditingController(text: existing?.currency.isNotEmpty == true ? existing!.currency : 'IDR');
    var isDefault = existing?.isDefault ?? false;
    var isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _card,
          title: Text(existing == null ? 'Add payment account' : 'Edit payment account', style: const TextStyle(color: _text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: bankCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(ctx, hintText: 'Bank ID (e.g. BCA)')),
                const SizedBox(height: 10),
                TextField(controller: acctCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(ctx, hintText: 'Account number')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(ctx, hintText: 'Account name')),
                const SizedBox(height: 10),
                TextField(controller: currencyCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(ctx, hintText: 'Currency (IDR)')),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default for currency', style: TextStyle(color: _text, fontSize: 13)),
                  value: isDefault,
                  onChanged: (v) => setDlg(() => isDefault = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active', style: TextStyle(color: _text, fontSize: 13)),
                  value: isActive,
                  onChanged: (v) => setDlg(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await financeReceiveAccountPut(
                    widget.conn,
                    BillingReceiveAccount(
                      id: existing?.id ?? Int64.ZERO,
                      bankId: bankCtrl.text.trim(),
                      accountNumber: acctCtrl.text.trim(),
                      accountName: nameCtrl.text.trim(),
                      currency: currencyCtrl.text.trim().toUpperCase(),
                      isDefault: isDefault,
                      isActive: isActive,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(uiFriendlyError(e, fallback: 'Save failed.'))));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    bankCtrl.dispose();
    acctCtrl.dispose();
    nameCtrl.dispose();
    currencyCtrl.dispose();
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _text,
          title: const Text('Payment accounts'),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            IconButton(onPressed: () => _editAccount(), icon: const Icon(Icons.add)),
          ],
        ),
        body: _loading
            ? const Center(child: UILoading())
            : RefreshIndicator(
                onRefresh: _load,
                child: _accounts.isEmpty
                    ? ListView(children: [
                        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444)))),
                        const SizedBox(height: 80),
                        const Center(child: Text('No payment accounts', style: TextStyle(color: _muted))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _accounts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final a = _accounts[i];
                          return Material(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => _editAccount(a),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF27272A))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text('${a.bankId} · ${a.accountNumber}', style: const TextStyle(color: _text, fontWeight: FontWeight.w600))),
                                        if (a.isDefault) const Chip(label: Text('Default', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                                        if (!a.isActive) const Chip(label: Text('Inactive', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(a.accountName, style: const TextStyle(color: _muted, fontSize: 12)),
                                    Text(a.currency, style: const TextStyle(color: _muted, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      );
}
