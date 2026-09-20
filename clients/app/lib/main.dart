import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/pages/auth/page_sign_in.dart';
import 'package:alienai_c35/pages/referral/page_referral_tree.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const C35App());
}

class C35App extends StatefulWidget {
  const C35App({super.key});

  @override
  State<C35App> createState() => _C35AppState();
}

class _C35AppState extends State<C35App> {
  final _auth = AuthService();
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuth);
    _auth.restore().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alien AI c35',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _auth.signedIn
              ? _HomeShell(auth: _auth)
              : PageSignIn(auth: _auth, onSignedIn: () => setState(() {})),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final conn = ReferralConn(uid: Session.instance.uid);
    return PageReferralTree(conn: conn, viewerId: Session.instance.uid);
  }
}
