import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_plan_sheet.dart';
import 'package:alienai_c35/widgets/ui/ui_root_error_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UiMsgError extends StatelessWidget {
  const UiMsgError({
    super.key,
    required this.message,
    this.detail,
    this.msgId = 0,
    this.reqId = '',
    this.onRetry,
    this.retrying = false,
    this.showIcon = true,
    this.onUpgrade,
  });

  final String message;
  final String? detail;
  final int msgId;
  final String reqId;
  final VoidCallback? onRetry;
  final bool retrying;
  final bool showIcon;
  final VoidCallback? onUpgrade;

  bool _isQuota(String msg, String? det) {
    if (uiIsQuotaError(msg)) return true;
    if (det != null && uiIsQuotaError(det)) return true;
    final lower = msg.toLowerCase();
    if (lower.contains('something went wrong') || lower.contains('timed out')) {
      final q = AppStore.instance.quota;
      if (q != null) {
        if (q.freemiumActive) {
          if (q.freemiumMsgsLimit > 0 && q.freemiumMsgsUsed >= q.freemiumMsgsLimit) return true;
          if (q.freemiumTokensLimit > 0 && q.freemiumTokensUsed >= q.freemiumTokensLimit) return true;
        }
        final b = AppStore.instance.billing;
        final bal = (b?.balanceUsd ?? 0.0) + (b?.balanceIdr ?? 0.0);
        if (bal <= 0.0) {
          if (q.alienAllow5hLimit > 0 && q.alienAllow5hUsed >= q.alienAllow5hLimit) return true;
          if (q.alienAllowWeeklyLimit > 0 && q.alienAllowWeeklyUsed >= q.alienAllowWeeklyLimit) return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final quota = _isQuota(message, detail);
    final displayMessage = quota && (message.contains('Something went wrong') || message.contains('timed out'))
        ? "You're out of quota. Upgrade your plan or top up your balance to continue."
        : message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  quota ? Icons.bolt_rounded : Icons.cloud_off_rounded,
                  size: 16,
                  color: quota ? const Color(0xFF38BDF8) : const Color(0xFFF87171),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayMessage, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFFF4F4F5))),
                  if (detail != null && detail!.trim().isNotEmpty && detail!.trim() != message.trim()) ...[
                    const SizedBox(height: 8),
                    UiRootErrorDetail(detail: detail!, msgId: msgId, reqId: reqId),
                  ],
                  const SizedBox(height: 6),
                  if (quota)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: onUpgrade ?? () => showBillingPlanSheet(context, ReferralConn(uid: Session.instance.uid)),
                          icon: const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF38BDF8)),
                          label: const Text('Upgrade plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8))),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.28)),
                            ),
                          ),
                        ),
                        if (onRetry != null)
                          TextButton.icon(
                            onPressed: retrying ? null : onRetry,
                            icon: retrying
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF71717A)))
                                : const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF71717A)),
                            label: Text(retrying ? 'Retrying…' : 'Retry', style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    )
                  else if (onRetry != null)
                    TextButton.icon(
                      onPressed: retrying ? null : onRetry,
                      icon: retrying
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399)))
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(retrying ? 'Retrying…' : 'Retry'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF34D399),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
