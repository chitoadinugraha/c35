import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// On-screen footer matching PDF "Powered by alien ai" branding.
class ReceiptPoweredFooter extends StatelessWidget {
  const ReceiptPoweredFooter({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Powered by ',
              style: TextStyle(color: Color(0xFF757575), fontSize: 11),
            ),
            SvgPicture.asset(
              'assets/icons/alien_receipt.svg',
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 4),
            const Text(
              'alien ai',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
