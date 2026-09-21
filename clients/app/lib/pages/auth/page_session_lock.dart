import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageSessionLock extends StatefulWidget {
  const PageSessionLock({super.key, required this.auth, required this.conn});

  final AuthService auth;
  final SettingsConn conn;

  @override
  State<PageSessionLock> createState() => _PageSessionLockState();
}

class _PageSessionLockState extends State<PageSessionLock> {
  late final _pinCtrl = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text('sessionLock.signOut'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
        content: Text('sessionLock.signOutConfirm'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('sessionLock.signOut'.tr())),
        ],
      ),
    );
    if (ok == true) await widget.auth.signOut();
  }

  Future<void> _unlockTap() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await widget.auth.unlockSession(widget.conn);
      if (!ok && mounted) setState(() => _error = 'sessionLock.unlockFailed'.tr());
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlockPin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await widget.auth.unlockSession(widget.conn, pin: _pinCtrl.text.trim());
      if (!ok && mounted) setState(() => _error = 'sessionLock.unlockFailed'.tr());
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinMode = widget.auth.sessionUnlockMode == 'pin' || widget.auth.sessionUnlockMode == 'pin_biometric';
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 56, color: Color(0xFF34D399)),
                  const SizedBox(height: 16),
                  Text('sessionLock.title'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('sessionLock.subtitle'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71717A))),
                  const SizedBox(height: 24),
                  if (!pinMode)
                    FilledButton(
                      onPressed: _busy ? null : _unlockTap,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)),
                      child: Text('sessionLock.activateButton'.tr()),
                    ),
                  if (pinMode) ...[
                    TextField(
                      controller: _pinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Color(0xFFF4F4F5)),
                      decoration: InputDecoration(labelText: 'sessionLock.pinHint'.tr()),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _unlockPin,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 48)),
                      child: Text('sessionLock.unlockWithPin'.tr()),
                    ),
                  ],
                  if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))],
                  const SizedBox(height: 24),
                  TextButton(onPressed: _busy ? null : _signOut, child: Text('sessionLock.signOut'.tr(), style: const TextStyle(color: Color(0xFF71717A)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
