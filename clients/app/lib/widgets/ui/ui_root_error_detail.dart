import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String rootErrorCopyText({required String detail, String? messageId}) {
  final text = detail.trim();
  if (text.isEmpty) return '';
  final id = messageId?.trim() ?? '';
  if (id.isEmpty) return text;
  return '[Message ID $id]\n$text';
}

class UiRootErrorDetail extends StatelessWidget {
  const UiRootErrorDetail({super.key, required this.detail, this.messageId});

  final String detail;
  final String? messageId;

  Widget _copyButton(BuildContext context) {
    final btn = InkWell(
      onTap: () => _copy(context),
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFFA1A1AA)),
      ),
    );
    if (Overlay.maybeOf(context) == null) return btn;
    return Tooltip(message: 'Copy error', child: btn);
  }

  void _copy(BuildContext context) {
    final text = rootErrorCopyText(detail: detail, messageId: messageId);
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Error copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
    );
  }

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                const SizedBox(width: 4),
                _copyButton(context),
              ],
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
