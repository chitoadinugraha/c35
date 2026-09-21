import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_topup_panel.dart';
import 'package:flutter/material.dart';

Future<void> billingTopupDialog(BuildContext context, {required ReferralConn conn, String currency = 'IDR', VoidCallback? onSubmitted}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF27272A))),
      title: Text('Top up · $currency', style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: UiBillingTopupPanel(
          conn: conn,
          currency: currency,
          onSubmitted: () {
            Navigator.of(ctx).pop();
            onSubmitted?.call();
          },
        ),
      ),
    ),
  );
}
