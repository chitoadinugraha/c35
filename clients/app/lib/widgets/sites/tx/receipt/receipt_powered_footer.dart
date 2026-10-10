import 'package:alienai_c35/widgets/sites/ui_powered_by_alien.dart';
import 'package:flutter/material.dart';

/// On-screen footer matching PDF / ESC-POS “Powered by alienai.id” branding.
class ReceiptPoweredFooter extends StatelessWidget {
  const ReceiptPoweredFooter({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: UiPoweredByAlien(fontSize: 11));
}
