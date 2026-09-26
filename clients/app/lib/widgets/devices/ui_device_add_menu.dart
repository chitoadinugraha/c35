import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/widgets/devices/in_device_pair.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiDeviceAddMenu extends StatelessWidget {
  const UiDeviceAddMenu({super.key, required this.store});

  final DeviceStore store;

  Future<void> _onAddPair(BuildContext context) async {
    final code = await inDevicePairAsk(context);
    if (code == null || !context.mounted) return;
    try {
      await store.pair(code);
      if (context.mounted) await uiAlertInfo(context, title: 'Device paired', message: 'The device is now linked to your account.');
    } catch (e) {
      if (context.mounted) await uiAlertError(context, e);
    }
  }

  Future<void> _onFlashComingSoon(BuildContext context) => uiAlertInfo(context, title: 'Coming soon', message: 'Flash IoT Device is not available yet.');

  @override
  Widget build(BuildContext context) => uiPopupMenuTooltipWrap(
        tooltip: 'Add device',
        menu: PopupMenuButton<String>(
          tooltip: uiPopupMenuTooltipText('Add device'),
          padding: EdgeInsets.zero,
          icon: uiPopupMenuIcon(Icons.add),
          iconSize: 18,
          onSelected: (v) => switch (v) {
            'pair' => _onAddPair(context),
            'flash' => _onFlashComingSoon(context),
            _ => null,
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'pair',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Add device'),
                subtitle: Text('Enter pairing code'),
              ),
            ),
            PopupMenuItem(
              value: 'flash',
              child: ListTile(
                leading: Icon(Icons.usb),
                title: Text('Flash IoT Device'),
                subtitle: Text('Coming soon'),
              ),
            ),
          ],
        ),
      );
}
