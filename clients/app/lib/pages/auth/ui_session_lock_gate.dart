import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/pages/auth/page_session_lock.dart';
import 'package:flutter/material.dart';

class UiSessionLockGate extends StatefulWidget {
  const UiSessionLockGate({super.key, required this.auth, required this.conn, required this.child});

  final AuthService auth;
  final SettingsConn conn;
  final Widget child;

  @override
  State<UiSessionLockGate> createState() => _UiSessionLockGateState();
}

class _UiSessionLockGateState extends State<UiSessionLockGate> {
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.auth.checkSessionStatus(widget.conn));
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auth.signedIn && widget.auth.sessionLocked) return PageSessionLock(auth: widget.auth, conn: widget.conn);
    return widget.child;
  }
}
