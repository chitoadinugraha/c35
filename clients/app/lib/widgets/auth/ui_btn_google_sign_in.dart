import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UiBtnGoogleSignIn extends StatelessWidget {
  const UiBtnGoogleSignIn({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'Continue with Google',
    this.busyLabel = 'Signing in…',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF15151A);
    const border = Color(0xFF26262E);
    const fg = Color(0xFFEEEEF0);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: border),
      ),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                SvgPicture.asset('assets/icons/google.svg', width: 18, height: 18),
              const SizedBox(width: 12),
              Text(
                busy ? busyLabel : label,
                style: const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
