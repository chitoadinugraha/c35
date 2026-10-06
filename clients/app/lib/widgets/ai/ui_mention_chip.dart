import 'package:flutter/material.dart';

class UiMentionChip extends StatelessWidget {
  const UiMentionChip({super.key, required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = label.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF18181B),
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFF3F3F46))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFFA1A1AA)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              tooltip: 'Clear mention',
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFA1A1AA)),
            ),
          ],
        ),
      ),
    );
  }
}
