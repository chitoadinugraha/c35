import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_action_btn.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_footer.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_shell.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageSignUp extends StatefulWidget {
  const PageSignUp({super.key, required this.auth, required this.onSignedUp});
  final AuthService auth;
  final VoidCallback onSignedUp;
  @override
  State<PageSignUp> createState() => _PageSignUpState();
}

class _PageSignUpState extends State<PageSignUp> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  String? _error;
  bool get _anyBusy => widget.auth.anyBusy;
  bool get _canSubmit => !_anyBusy && _nameCtrl.text.trim().isNotEmpty && authLoginIsEmailOrPhone(_emailCtrl.text) && _passwordCtrl.text.length >= 8 && _passwordCtrl.text == _confirmCtrl.text;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _error = null);
    try {
      await widget.auth.signUp(name: _nameCtrl.text, email: authLoginNormalize(_emailCtrl.text), password: _passwordCtrl.text, referralCode: _referralCtrl.text);
      widget.onSignedUp();
    } catch (e) {
      if (mounted) setState(() => _error = uiAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: UiAuthShell(
        title: 'Create account',
        subtitle: 'Alien AI',
        footer: UiAuthFooter(version: appVersionDetailLabel()),
        children: [
          TextField(controller: _nameCtrl, enabled: !_anyBusy, decoration: UiInputDecoration.of(context, labelText: 'Name'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, enabled: !_anyBusy, decoration: UiInputDecoration.of(context, labelText: 'Email / Phone Number'), keyboardType: TextInputType.text, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            enabled: !_anyBusy,
            obscureText: _obscurePassword,
            decoration: UiInputDecoration.of(context, labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            enabled: !_anyBusy,
            obscureText: _obscureConfirm,
            decoration: UiInputDecoration.of(context, labelText: 'Confirm', suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralCtrl,
            enabled: !_anyBusy,
            inputFormatters: [TextInputFormatter.withFunction((o, n) => TextEditingValue(text: referralCodeInputFormat(n.text), selection: TextSelection.collapsed(offset: referralCodeInputFormat(n.text).length)))],
            decoration: UiInputDecoration.of(context, labelText: 'Referral (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          UiAuthActionBtn(label: 'Sign up', onPressed: _canSubmit ? _submit : null, busy: _anyBusy),
        ],
      ),
    );
  }
}
