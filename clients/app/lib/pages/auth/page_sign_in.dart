import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/pages/auth/page_sign_up.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_action_btn.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_footer.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_shell.dart';
import 'package:alienai_c35/widgets/auth/ui_btn_google_sign_in.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

class PageSignIn extends StatefulWidget {
  const PageSignIn({super.key, required this.auth, this.onSignedIn});
  final AuthService auth;
  final VoidCallback? onSignedIn;
  @override
  State<PageSignIn> createState() => _PageSignInState();
}

enum _AuthAction { none, password, google }

class _PageSignInState extends State<PageSignIn> {
  late final AuthService _auth = widget.auth;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _entering = false;
  var _lastAction = _AuthAction.none;
  String? _error;
  bool get _anyBusy => _auth.anyBusy || _entering || _auth.signedIn;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() { if (mounted) setState(() {}); }

  void _enterApp() {
    if (mounted) setState(() => _entering = true);
    widget.onSignedIn?.call();
  }

  Future<void> _signInPassword() async {
    if (_anyBusy) return;
    setState(() { _error = null; _lastAction = _AuthAction.password; });
    try {
      await _auth.signInWithPassword(identifier: authLoginNormalize(_identifierController.text), password: _passwordController.text);
      if (mounted) setState(() => _entering = true);
      _enterApp();
    } catch (e) {
      if (mounted) setState(() { _entering = false; _error = uiAuthError(e); });
    }
  }

  Future<void> _signInGoogle() async {
    if (_anyBusy) return;
    setState(() { _error = null; _lastAction = _AuthAction.google; });
    try {
      await _auth.signInWithGoogle();
      if (mounted) setState(() => _entering = true);
      _enterApp();
    } catch (e) {
      if (mounted) setState(() { _entering = false; _error = uiAuthError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoogleBusy = (_auth.busy == AuthSignInBusy.google) || (_entering && _lastAction == _AuthAction.google);
    final isPasswordBusy = (_auth.busy == AuthSignInBusy.password) || (_entering && _lastAction == _AuthAction.password);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: UiAuthShell(
        title: 'Welcome to Alien AI',
        subtitle: 'Intelligent, automated Pair & Bot assistant',
        footer: UiAuthFooter(version: appVersionLabel()),
        children: [
          UiBtnGoogleSignIn(onPressed: _anyBusy ? null : _signInGoogle, busy: isGoogleBusy),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Divider(color: Color(0xFF222227))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF71717A)))),
            const Expanded(child: Divider(color: Color(0xFF222227))),
          ]),
          const SizedBox(height: 18),
          TextField(
            controller: _identifierController,
            enabled: !_anyBusy,
            decoration: UiInputDecoration.of(context, labelText: 'Alien AI ID / Email / Phone Number', hintText: 'chito', suffixText: authLoginAlienSuffix(_identifierController.text)),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            enabled: !_anyBusy,
            obscureText: _obscurePassword,
            decoration: UiInputDecoration.of(
              context,
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF8E8E98), size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signInPassword(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF2E1515), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF5C2020))),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
            ),
          ],
          const SizedBox(height: 20),
          UiAuthActionBtn(label: 'Sign in', onPressed: _anyBusy ? null : _signInPassword, busy: isPasswordBusy),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text("Don't have an account? ", style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E98))),
              GestureDetector(
                onTap: _anyBusy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PageSignUp(auth: _auth, onSignedUp: _enterApp))),
                child: Text('Sign up', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
