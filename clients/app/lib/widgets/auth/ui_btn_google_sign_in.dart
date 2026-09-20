import 'package:flutter/material.dart';

class UiBtnGoogleSignIn extends StatelessWidget {
  const UiBtnGoogleSignIn({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('G', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        label: Text(busy ? 'Signing in…' : 'Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF3F3F46)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
}
