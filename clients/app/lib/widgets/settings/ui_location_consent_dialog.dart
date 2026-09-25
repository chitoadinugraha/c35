import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiLocationConsentDialog extends StatelessWidget {
  const UiLocationConsentDialog({super.key});

  /// `true` = Continue, `false` = Not now.
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const UiLocationConsentDialog(),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      title: Text('settings.locationConsentTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 18, fontWeight: FontWeight.w600)),
      content: Text('settings.locationConsentBody'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.45)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('settings.locationConsentNotNow'.tr())),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text('settings.locationConsentContinue'.tr())),
      ],
    );
  }
}
