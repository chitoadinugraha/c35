import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiSettingsUnlockMode extends StatefulWidget {
  const UiSettingsUnlockMode({super.key, required this.account, required this.currentMode, required this.hasPin, this.onModeChanged});
  final AccountApi account;
  final String currentMode;
  final bool hasPin;
  final ValueChanged<String>? onModeChanged;

  @override
  State<UiSettingsUnlockMode> createState() => _UiSettingsUnlockModeState();
}

class _UiSettingsUnlockModeState extends State<UiSettingsUnlockMode> {
  late String _mode = widget.currentMode.isEmpty ? 'tap' : widget.currentMode;

  @override
  void didUpdateWidget(covariant UiSettingsUnlockMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode) _mode = widget.currentMode.isEmpty ? 'tap' : widget.currentMode;
  }

  String _modeLabel(String mode) => switch (mode) {
        'pin_biometric' => 'settings.sessionUnlockModePinBiometric'.tr(),
        'pin' => 'settings.sessionUnlockModePin'.tr(),
        _ => 'settings.sessionUnlockModeTap'.tr(),
      };

  IconData _modeIcon(String mode) => switch (mode) {
        'pin_biometric' => Icons.fingerprint_rounded,
        'pin' => Icons.pin_rounded,
        _ => Icons.touch_app_rounded,
      };

  Future<void> _selectMode() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('settings.sessionUnlockMode'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.touch_app_rounded, color: Color(0xFF71717A)), title: Text('settings.sessionUnlockModeTap'.tr(), style: const TextStyle(color: Color(0xFFE4E4E7))), subtitle: Text('settings.sessionUnlockModeSubtitleTap'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)), trailing: _mode == 'tap' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)) : null, onTap: () => Navigator.pop(ctx, 'tap')),
            ListTile(leading: const Icon(Icons.pin_rounded, color: Color(0xFF71717A)), title: Text('settings.sessionUnlockModePin'.tr(), style: const TextStyle(color: Color(0xFFE4E4E7))), subtitle: Text('settings.sessionUnlockModeSubtitlePin'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)), trailing: _mode == 'pin' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)) : null, onTap: () => Navigator.pop(ctx, 'pin')),
            ListTile(leading: const Icon(Icons.fingerprint_rounded, color: Color(0xFF71717A)), title: Text('settings.sessionUnlockModePinBiometric'.tr(), style: const TextStyle(color: Color(0xFFE4E4E7))), subtitle: Text('settings.sessionUnlockModeSubtitlePinBiometric'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)), trailing: _mode == 'pin_biometric' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)) : null, onTap: () => Navigator.pop(ctx, 'pin_biometric')),
          ]),
        ),
      ),
    );
    if (selected == null || selected == _mode || !mounted) return;
    if ((selected == 'pin' || selected == 'pin_biometric') && !widget.hasPin) {
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF18181B), title: Text('settings.sessionUnlockMode'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))), content: Text('settings.sessionUnlockModePinNeedsPin'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA))), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))]));
      return;
    }
    try {
      final savedMode = await widget.account.sessionUnlockModePut(selected);
      if (!mounted) return;
      setState(() => _mode = savedMode);
      widget.onModeChanged?.call(savedMode);
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF18181B), title: Text('settings.sessionUnlockMode'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))), content: Text(uiFriendlyError(e), style: const TextStyle(color: Color(0xFFA1A1AA))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))]));
    }
  }

  @override
  Widget build(BuildContext context) => UiSettingsTile(icon: _modeIcon(_mode), title: 'settings.sessionUnlockMode'.tr(), subtitle: _modeLabel(_mode), onTap: _selectMode);
}
