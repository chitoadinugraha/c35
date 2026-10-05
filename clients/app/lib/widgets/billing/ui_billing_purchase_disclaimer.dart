import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiBillingPurchaseDisclaimer extends StatelessWidget {
  const UiBillingPurchaseDisclaimer({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.only(top: 8),
        child: Text(
          'billing.purchaseNonRefundable'.tr(),
          style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, height: 1.35),
        ),
      );
}
