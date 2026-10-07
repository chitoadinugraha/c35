import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_platform.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_play_topup_panel.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_topup_panel.dart';
import 'package:flutter/material.dart';

Future<void> billingTopupDialog(BuildContext context, {required ReferralConn conn, String currency = 'IDR', VoidCallback? onSubmitted}) async {
  final usePlay = billingUsePlayCheckout();
  final title = usePlay ? 'Top up via Google Play' : (billingShowInAppTopup() ? 'Top up · $currency' : 'Credit · $currency');
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF27272A))),
      title: Text(title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: usePlay
              ? UiBillingPlayTopupPanel(conn: conn, onSubmitted: onSubmitted)
              : UiBillingTopupPanel(
                  conn: conn,
                  currency: currency,
                  onSubmitted: onSubmitted,
                ),
        ),
      ),
    ),
  );
}
