import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/voucher_link.dart';
import 'package:alienai_c35/widgets/referral/ui_billing_package_redeem.dart';
import 'package:flutter/material.dart';

/// Opens the redeem dialog when a voucher link is waiting and the user is signed in.
class VoucherRedeemHost extends StatefulWidget {
  const VoucherRedeemHost({super.key, required this.child});

  final Widget child;

  @override
  State<VoucherRedeemHost> createState() => _VoucherRedeemHostState();
}

class _VoucherRedeemHostState extends State<VoucherRedeemHost> {
  var _opening = false;

  @override
  void initState() {
    super.initState();
    VoucherLink.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    VoucherLink.unlisten(_open);
    super.dispose();
  }

  void _open() {
    if (!mounted || _opening) return;
    final code = VoucherLink.pending;
    if (code == null || code.isEmpty) return;
    VoucherLink.pending = null;
    _opening = true;
    unawaited(_show(code));
  }

  Future<void> _show(String code) async {
    try {
      await billingPackageRedeemDialog(context, conn: ReferralConn(), initialCode: code);
    } finally {
      _opening = false;
      if (mounted) _open();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
