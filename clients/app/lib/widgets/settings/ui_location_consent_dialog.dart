import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiLocationConsentDialog extends StatelessWidget {
  const UiLocationConsentDialog({super.key});

  /// `true` = Continue, `false` = Not now.
  static Future<bool?> show(BuildContext context) =>
      uiDialogShow<bool>(context: context, builder: (_) => const UiLocationConsentDialog());

  @override
  Widget build(BuildContext context) => UiDialog(
        maxWidth: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiDialogHeader(title: 'settings.locationConsentTitle'.tr(), onClose: () => Navigator.of(context).pop(false)),
            Text('settings.locationConsentBody'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.45)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text('settings.locationConsentContinue'.tr())),
            ),
          ],
        ),
      );
}
