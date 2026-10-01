import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

Future<void> billingPurchaseSuccessDialogShow(
  BuildContext context, {
  required List<BillingEntitlementDoc> entitlements,
  Int64 highlightEntitlementId = Int64.ZERO,
  String title = 'Purchase complete',
  String? subtitle,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _BillingPurchaseSuccessDialog(
      entitlements: entitlements,
      highlightEntitlementId: highlightEntitlementId,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _BillingPurchaseSuccessDialog extends StatelessWidget {
  const _BillingPurchaseSuccessDialog({
    required this.entitlements,
    required this.highlightEntitlementId,
    required this.title,
    this.subtitle,
  });

  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF3F3F46);
  static const _accent = Color(0xFF34D399);

  final List<BillingEntitlementDoc> entitlements;
  final Int64 highlightEntitlementId;
  final String title;
  final String? subtitle;

  List<BillingEntitlementDoc> get _sorted {
    final items = [...entitlements];
    items.sort((a, b) => a.expiresTsMs.compareTo(b.expiresTsMs));
    return items;
  }

  String _expiresLabel(BillingEntitlementDoc doc) {
    final ms = doc.expiresTsMs.toInt();
    if (ms <= 0) return 'No expiry';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _titleFor(BillingEntitlementDoc doc) {
    if (doc.planName.trim().isNotEmpty) return doc.planName;
    if (doc.planSlug.trim().isNotEmpty) return billingPlanTierLabel(doc.planSlug);
    if (doc.creditIdr > 0) return 'Credit';
    return 'Entitlement';
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _accent, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                          if (subtitle != null && subtitle!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(subtitle!, style: const TextStyle(color: _muted, fontSize: 12, height: 1.35)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: _muted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              Flexible(
                child: _sorted.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No active entitlements yet.', style: TextStyle(color: _muted, fontSize: 13)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final doc = _sorted[i];
                          final highlight = doc.highlight ||
                              (highlightEntitlementId > Int64.ZERO && doc.id == highlightEntitlementId);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: highlight ? const Color(0x1434D399) : const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: highlight ? _accent : _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _titleFor(doc),
                                        style: TextStyle(
                                          color: highlight ? _accent : _text,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (highlight)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                        child: const Text('New', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Expires ${_expiresLabel(doc)}', style: const TextStyle(color: _muted, fontSize: 12)),
                                if (doc.creditIdr > 0) ...[
                                  const SizedBox(height: 2),
                                  Text('Credit Rp ${uiFmtGroupedInt(doc.creditIdr.round())}', style: const TextStyle(color: _muted, fontSize: 11)),
                                ],
                                if (doc.source.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(doc.source, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              ),
            ],
          ),
        ),
      );
}
