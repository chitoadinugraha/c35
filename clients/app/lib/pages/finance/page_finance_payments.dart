import 'dart:typed_data';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/finance_api.dart';
import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

enum _PaymentKind { topup, withdraw }

enum _PaymentsSection { pending, historyTopup, historyWithdraw }

class _PaymentItem {
  const _PaymentItem.topup(this.topup) : withdraw = null, kind = _PaymentKind.topup;
  const _PaymentItem.withdraw(this.withdraw) : topup = null, kind = _PaymentKind.withdraw;

  final _PaymentKind kind;
  final BillingTopupQueueItem? topup;
  final CommissionWithdrawQueueItem? withdraw;
}

class PageFinancePayments extends StatefulWidget {
  const PageFinancePayments({super.key, required this.conn, required this.canReview});

  final ReferralConn conn;
  final bool canReview;

  @override
  State<PageFinancePayments> createState() => _PageFinancePaymentsState();
}

class _PageFinancePaymentsState extends State<PageFinancePayments> {
  static const _bg = Color(0xFF08080A);
  static const _card = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);

  var _section = _PaymentsSection.pending;
  var _loading = true;
  String? _error;
  List<BillingTopupQueueItem> _pendingTopups = [];
  List<CommissionWithdrawQueueItem> _pendingWithdraws = [];
  List<BillingTopupQueueItem> _historyTopups = [];
  List<CommissionWithdrawQueueItem> _historyWithdraws = [];
  var _query = '';
  late final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pendingTopups = await financeTopupList(widget.conn, status: 'pending');
      final pendingWithdraws = await financeWithdrawList(widget.conn, status: 'pending');
      final historyTopups = await financeTopupList(widget.conn, status: 'history');
      final historyWithdraws = await financeWithdrawList(widget.conn, status: 'history');
      if (!mounted) return;
      setState(() {
        _pendingTopups = pendingTopups;
        _pendingWithdraws = pendingWithdraws;
        _historyTopups = historyTopups;
        _historyWithdraws = historyWithdraws;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiFriendlyError(e, fallback: 'Could not load payments.');
      });
    }
  }

  List<_PaymentItem> get _pendingItems {
    final items = <_PaymentItem>[
      for (final t in _pendingTopups) _PaymentItem.topup(t),
      for (final w in _pendingWithdraws) _PaymentItem.withdraw(w),
    ];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty ? items : items.where((i) => _itemUserName(i).toLowerCase().contains(q)).toList();
    filtered.sort((a, b) => _itemCreatedMs(b).compareTo(_itemCreatedMs(a)));
    return filtered;
  }

  List<_PaymentItem> _historyItemsFor(_PaymentsSection section) {
    final raw = section == _PaymentsSection.historyTopup
        ? [for (final t in _historyTopups) _PaymentItem.topup(t)]
        : [for (final w in _historyWithdraws) _PaymentItem.withdraw(w)];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? raw
        : raw.where((i) {
            final bank = i.withdraw?.bankShortName.toLowerCase() ?? '';
            final acct = i.withdraw?.accountName.toLowerCase() ?? '';
            return _itemUserName(i).toLowerCase().contains(q) || bank.contains(q) || acct.contains(q);
          }).toList();
    filtered.sort((a, b) => _itemCreatedMs(b).compareTo(_itemCreatedMs(a)));
    return filtered;
  }

  String _itemUserName(_PaymentItem item) => item.kind == _PaymentKind.topup ? item.topup!.userName : item.withdraw!.userName;

  int _itemCreatedMs(_PaymentItem item) => item.kind == _PaymentKind.topup ? item.topup!.createdTsMs.toInt() : item.withdraw!.createdTsMs.toInt();

  Future<void> _openPending(_PaymentItem item) async {
    final changed = item.kind == _PaymentKind.topup ? await _showTopupReviewDialog(item.topup!) : await _showWithdrawReviewDialog(item.withdraw!);
    if (changed == true) await _load();
  }

  Future<bool?> _showTopupReviewDialog(BillingTopupQueueItem request) async {
    final reasonCtrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Review deposit', style: TextStyle(color: _text)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(request.userName, style: const TextStyle(color: _text, fontWeight: FontWeight.w600)),
              if (request.userHandle.isNotEmpty) Text(request.userHandle, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
              Text(moneyFmtIdr(request.amountIdr), style: const TextStyle(color: Color(0xFFD97706), fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (request.proofUrl.isNotEmpty)
                InkWell(
                  onTap: () => showDialog(
                    context: ctx,
                    builder: (_) => Dialog(backgroundColor: _bg, child: InteractiveViewer(child: Image.network(request.proofUrl, fit: BoxFit.contain))),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(request.proofUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              if (widget.canReview) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(ctx, hintText: 'Reason (optional for reject)'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (widget.canReview) ...[
            TextButton(
              onPressed: () async {
                try {
                  await financeTopupReview(widget.conn, requestId: request.requestId.toInt(), action: 'reject', reason: reasonCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(uiFriendlyError(e, fallback: 'Reject failed.'))));
                }
              },
              child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444))),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await financeTopupReview(widget.conn, requestId: request.requestId.toInt(), action: 'approve');
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(uiFriendlyError(e, fallback: 'Approve failed.'))));
                }
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showWithdrawReviewDialog(CommissionWithdrawQueueItem request) async {
    final reasonCtrl = TextEditingController();
    Uint8List? proofBytes;
    var proofMime = 'image/jpeg';
    var uploading = false;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _card,
          title: const Text('Review withdrawal', style: TextStyle(color: _text)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(request.userName, style: const TextStyle(color: _text, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(moneyFmtIdr(request.amountIdr), style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${request.bankShortName} · ${request.accountNumber}', style: const TextStyle(color: _muted, fontSize: 12)),
                Text(request.accountName, style: const TextStyle(color: _muted, fontSize: 12)),
                if (widget.canReview) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            final picked = await askMedia(context: ctx, types: const [MediaType.image], allowMultiple: false);
                            if (picked == null || picked.isEmpty) return;
                            setDlg(() {
                              proofBytes = picked.first.bytes;
                              proofMime = picked.first.mime;
                            });
                          },
                    icon: Icon(proofBytes == null ? Icons.upload_file : Icons.check_circle, size: 16),
                    label: Text(proofBytes == null ? 'Upload transfer proof' : 'Proof selected'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    style: const TextStyle(color: _text),
                    decoration: UiInputDecoration.of(ctx, hintText: 'Reason (optional for decline)'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            if (widget.canReview) ...[
              TextButton(
                onPressed: () async {
                  try {
                    await financeWithdrawReview(widget.conn, requestId: request.requestId.toInt(), action: 'decline', reason: reasonCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(uiFriendlyError(e, fallback: 'Decline failed.'))));
                  }
                },
                child: const Text('Decline', style: TextStyle(color: Color(0xFFEF4444))),
              ),
              FilledButton(
                onPressed: uploading
                    ? null
                    : () async {
                        if (proofBytes == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Upload transfer proof to approve.')));
                          return;
                        }
                        setDlg(() => uploading = true);
                        try {
                          final uploaded = await casUpload(bytes: proofBytes!, mime: proofMime, name: 'withdraw-proof.jpg');
                          if (uploaded == null || uploaded.url.isEmpty) throw Exception('Upload unavailable');
                          await financeWithdrawReview(
                            widget.conn,
                            requestId: request.requestId.toInt(),
                            action: 'approve',
                            transferProofUrl: uploaded.url,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(uiFriendlyError(e, fallback: 'Approve failed.'))));
                        } finally {
                          if (ctx.mounted) setDlg(() => uploading = false);
                        }
                      },
                child: uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Approve'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingTopups.length + _pendingWithdraws.length;
    final items = switch (_section) {
      _PaymentsSection.pending => _pendingItems,
      _PaymentsSection.historyTopup => _historyItemsFor(_PaymentsSection.historyTopup),
      _PaymentsSection.historyWithdraw => _historyItemsFor(_PaymentsSection.historyWithdraw),
    };
    final showStatus = _section != _PaymentsSection.pending;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: Row(
          children: [
            const Text('Payments'),
            if (pendingCount > 0) ...[const SizedBox(width: 8), Badge(label: Text('$pendingCount'))],
          ],
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<_PaymentsSection>(
              segments: const [
                ButtonSegment(value: _PaymentsSection.pending, label: Text('Pending'), icon: Icon(Icons.inbox_outlined, size: 16)),
                ButtonSegment(value: _PaymentsSection.historyTopup, label: Text('Deposits'), icon: Icon(Icons.south_west, size: 16)),
                ButtonSegment(value: _PaymentsSection.historyWithdraw, label: Text('Withdraw'), icon: Icon(Icons.north_east, size: 16)),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, hintText: 'Search user, bank, or account'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444)))),
          Expanded(child: _buildListBody(items, showStatus)),
        ],
      ),
    );
  }

  Widget _buildListBody(List<_PaymentItem> items, bool showStatus) {
    if (_loading) return const Center(child: UILoading());
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text('No requests', style: TextStyle(color: _muted))),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) => _PaymentTile(
                item: items[i],
                showStatus: showStatus,
                onTap: _section == _PaymentsSection.pending ? () => _openPending(items[i]) : null,
              ),
            ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.item, this.showStatus = false, this.onTap});

  final _PaymentItem item;
  final bool showStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTopup = item.kind == _PaymentKind.topup;
    final name = isTopup ? item.topup!.userName : item.withdraw!.userName;
    final pic = isTopup ? item.topup!.userPic : item.withdraw!.userPic;
    final handle = isTopup ? item.topup!.userHandle : '';
    final createdMs = isTopup ? item.topup!.createdTsMs.toInt() : item.withdraw!.createdTsMs.toInt();
    final created = createdMs > 0 ? DateTime.fromMillisecondsSinceEpoch(createdMs).toLocal().toString().substring(0, 16) : '';
    final amount = isTopup ? moneyFmtIdr(item.topup!.amountIdr) : moneyFmtIdr(item.withdraw!.amountIdr);
    final subtitle = isTopup
        ? created
        : [if (item.withdraw!.bankShortName.isNotEmpty) item.withdraw!.bankShortName, if (item.withdraw!.accountNumber.isNotEmpty) item.withdraw!.accountNumber, created].join(' · ');
    final status = isTopup ? item.topup!.status : item.withdraw!.status;

    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF27272A))),
          child: Row(
            children: [
              UiUserAvatar(name: name, handle: handle, pic: pic, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (showStatus) Text(status, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                  ],
                ),
              ),
              Text(amount, style: TextStyle(color: isTopup ? const Color(0xFFD97706) : const Color(0xFF34D399), fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
