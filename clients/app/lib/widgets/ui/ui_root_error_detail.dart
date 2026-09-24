import 'package:flutter/material.dart';

class UiRootErrorDetail extends StatelessWidget {
  const UiRootErrorDetail({super.key, required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final text = detail.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF3F3F46)),
              ),
              child: const Text('Root only', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFA1A1AA), letterSpacing: 0.2)),
            ),
            const SizedBox(height: 6),
            SelectableText(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFA1A1AA), fontFamily: 'Consolas'),
            ),
          ],
        ),
      ),
    );
  }
}
