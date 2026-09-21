import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

class PageNavStub extends StatelessWidget {
  const PageNavStub({super.key, required this.title, required this.icon, this.subtitle = 'Coming soon'});

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) => UiPage(
        title: title,
        subtitle: subtitle,
        onBack: () => Navigator.pop(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: const Color(0xFF22C55E)),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}
