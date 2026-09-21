import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/widgets/devices/in_device_pair.dart';
import 'package:flutter/material.dart';

class UiDeviceAddMenu extends StatelessWidget {
  const UiDeviceAddMenu({super.key, required this.store});

  final DeviceStore store;

  Future<void> _onAddPair(BuildContext context) async {
    final code = await inDevicePairAsk(context);
    if (code == null || !context.mounted) return;
    try {
      await store.pair(code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device paired')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _onFlashComingSoon(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flash device — coming soon')));

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.add, color: Color(0xFFF4F4F5)),
        tooltip: 'Add device',
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
              title: Text('Flash device'),
              subtitle: Text('Coming soon'),
            ),
          ),
        ],
      );
}
