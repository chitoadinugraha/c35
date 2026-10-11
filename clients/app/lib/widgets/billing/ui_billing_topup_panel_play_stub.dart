import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:flutter/material.dart';

/// Play Store AAB: wallet top-up UI is not compiled in; dialog uses [UiBillingPlayTopupPanel].
class UiBillingTopupPanel extends StatelessWidget {
  const UiBillingTopupPanel({super.key, required this.conn, this.currency = 'IDR', this.onSubmitted});

  final ReferralConn conn;
  final String currency;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Credit is added through Google Play. Close this dialog and use Top up again if needed.',
      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, height: 1.4),
    );
  }
}
