import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<T?> runWebDeferredModule<T>({
  required BuildContext context,
  required Future<void> Function() loadModule,
  required String loadingLabel,
  required Future<T?> Function() action,
}) async {
  if (!kIsWeb) return action();
  if (!context.mounted) return null;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(loadingLabel)),
          ],
        ),
      ),
    ),
  );
  try {
    await loadModule();
    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();
    return await action();
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    rethrow;
  }
}

String webModuleLoadingMailLabel() => 'mail.loadingModule'.tr();
String webModuleLoadingCallLabel() => 'live.loadingModule'.tr();
String webModuleLoadingDevicesLabel() => 'devices.loadingModule'.tr();
