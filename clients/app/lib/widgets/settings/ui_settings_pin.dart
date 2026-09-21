import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UiSettingsPin extends StatefulWidget {
  const UiSettingsPin({super.key, required this.account, required this.hasPin, this.onPinChanged});
  final AccountApi account;
  final bool hasPin;
  final ValueChanged<bool>? onPinChanged;

  @override
  State<UiSettingsPin> createState() => _UiSettingsPinState();
}

class _UiSettingsPinState extends State<UiSettingsPin> {
  late bool _hasPin = widget.hasPin;

  @override
  void didUpdateWidget(covariant UiSettingsPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasPin != widget.hasPin) _hasPin = widget.hasPin;
  }

  Future<void> _openPinDialog() async {
    final currentCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final result = await showDialog<({String? current, String newPin})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final newPin = pinCtrl.text.trim();
          final confirm = confirmCtrl.text.trim();
          final pinOk = newPin.length >= 4 && newPin.length <= 8 && RegExp(r'^\d+$').hasMatch(newPin);
          final match = newPin == confirm;
          final oldOk = !_hasPin || currentCtrl.text.trim().isNotEmpty;
          final canSave = oldOk && pinOk && match;
          return AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: Text(_hasPin ? 'settings.changePin'.tr() : 'settings.setPin'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
            content: SizedBox(
              width: 340,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_hasPin)
                  TextField(controller: currentCtrl, obscureText: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: InputDecoration(labelText: 'settings.currentPin'.tr()), onChanged: (_) => setDialogState(() {})),
                if (_hasPin) const SizedBox(height: 12),
                TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: InputDecoration(labelText: 'settings.newPin'.tr(), errorText: newPin.isNotEmpty && !pinOk ? 'settings.pinMinError'.tr() : null), onChanged: (_) => setDialogState(() {})),
                const SizedBox(height: 12),
                TextField(controller: confirmCtrl, obscureText: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: InputDecoration(labelText: 'settings.confirmPin'.tr(), errorText: confirm.isNotEmpty && !match ? 'settings.pinMismatch'.tr() : null), onChanged: (_) => setDialogState(() {})),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
              FilledButton(onPressed: canSave ? () => Navigator.pop(ctx, (current: _hasPin ? currentCtrl.text.trim() : null, newPin: newPin)) : null, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black), child: Text('common.save'.tr())),
            ],
          );
        },
      ),
    );
    currentCtrl.dispose();
    pinCtrl.dispose();
    confirmCtrl.dispose();
    if (result == null || !mounted) return;
    try {
      await widget.account.pinSet(currentPin: result.current, newPin: result.newPin);
      if (!mounted) return;
      setState(() => _hasPin = true);
      widget.onPinChanged?.call(true);
      if (mounted) {
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF18181B), title: Text('settings.pinSaved'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))]));
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF18181B), title: Text('settings.pinSaveFailed'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))), content: Text(uiFriendlyError(e), style: const TextStyle(color: Color(0xFFA1A1AA))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))]));
    }
  }

  @override
  Widget build(BuildContext context) => UiSettingsTile(icon: Icons.pin_rounded, title: _hasPin ? 'settings.changePin'.tr() : 'settings.setPin'.tr(), subtitle: _hasPin ? 'settings.pinSubtitleChange'.tr() : 'settings.pinSubtitleSet'.tr(), onTap: _openPinDialog);
}
