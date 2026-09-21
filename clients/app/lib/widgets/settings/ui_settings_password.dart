import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/settings/ui_settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiSettingsPassword extends StatefulWidget {
  const UiSettingsPassword({super.key, required this.account, required this.hasPassword, this.onPasswordChanged});
  final AccountApi account;
  final bool hasPassword;
  final ValueChanged<bool>? onPasswordChanged;

  @override
  State<UiSettingsPassword> createState() => _UiSettingsPasswordState();
}

class _UiSettingsPasswordState extends State<UiSettingsPassword> {
  late bool _hasPassword = widget.hasPassword;

  @override
  void didUpdateWidget(covariant UiSettingsPassword oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasPassword != widget.hasPassword) _hasPassword = widget.hasPassword;
  }

  Future<void> _openPasswordDialog() async {
    final result = await showDialog<({String current, String newPass})>(
      context: context,
      builder: (ctx) => _PasswordSetDialog(hasPassword: _hasPassword),
    );
    if (result == null || !mounted) return;
    try {
      await widget.account.passwordSet(currentPassword: result.current, newPassword: result.newPass);
      if (!mounted) return;
      setState(() => _hasPassword = true);
      widget.onPasswordChanged?.call(true);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: Text('settings.passwordSaved'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: Text('settings.passwordSaveFailed'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
          content: Text(uiFriendlyError(e), style: const TextStyle(color: Color(0xFFA1A1AA))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.ok'.tr()))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => UiSettingsTile(
        icon: Icons.lock_outline,
        title: _hasPassword ? 'settings.changePassword'.tr() : 'settings.setPassword'.tr(),
        subtitle: _hasPassword ? 'settings.passwordSubtitleChange'.tr() : 'settings.passwordSubtitleSet'.tr(),
        onTap: _openPasswordDialog,
      );
}

class _PasswordSetDialog extends StatefulWidget {
  const _PasswordSetDialog({required this.hasPassword});
  final bool hasPassword;

  @override
  State<_PasswordSetDialog> createState() => _PasswordSetDialogState();
}

class _PasswordSetDialogState extends State<_PasswordSetDialog> {
  late final _currentCtrl = TextEditingController();
  late final _passCtrl = TextEditingController();
  late final _confirmCtrl = TextEditingController();
  late bool _obscureCurrent = true;
  late bool _obscurePass = true;
  late bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, required bool obscure, required VoidCallback onToggle, String? errorText}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF71717A)),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF8E8E98), size: 20),
          onPressed: onToggle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final passOk = pass.length >= 8;
    final match = pass == confirm;
    final oldOk = !widget.hasPassword || _currentCtrl.text.isNotEmpty;
    final canSave = oldOk && passOk && match;
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text(widget.hasPassword ? 'settings.changePassword'.tr() : 'settings.setPassword'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.hasPassword) ...[
            TextField(controller: _currentCtrl, autofocus: true, obscureText: _obscureCurrent, style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: _dec(label: 'settings.currentPassword'.tr(), obscure: _obscureCurrent, onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent)), onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _passCtrl,
            autofocus: !widget.hasPassword,
            obscureText: _obscurePass,
            style: const TextStyle(color: Color(0xFFF4F4F5)),
            decoration: _dec(label: 'settings.newPassword'.tr(), obscure: _obscurePass, onToggle: () => setState(() => _obscurePass = !_obscurePass), errorText: pass.isNotEmpty && !passOk ? 'settings.passwordMinError'.tr() : null),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: Color(0xFFF4F4F5)),
            decoration: _dec(label: 'settings.confirmPassword'.tr(), obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm), errorText: confirm.isNotEmpty && !match ? 'settings.passwordMismatch'.tr() : null),
            onChanged: (_) => setState(() {}),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
        FilledButton(
          onPressed: canSave ? () => Navigator.pop(context, (current: _currentCtrl.text, newPass: _passCtrl.text)) : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}
