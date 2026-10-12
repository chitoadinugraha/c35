import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String rootErrorCopyHeader({int msgId = 0, String reqId = ''}) {
  final build = csaiVersionBuild();
  if (msgId > 0) return '[Version: $build, Message ID: $msgId]';
  final rid = reqId.trim();
  if (rid.isNotEmpty) return '[Version: $build, Request ID: $rid]';
  return appVersionErrorCopyPrefix();
}

String rootErrorCopyText({required String detail, int msgId = 0, String reqId = ''}) {
  final text = detail.trim();
  if (text.isEmpty) return '';
  return '${rootErrorCopyHeader(msgId: msgId, reqId: reqId)}\n$text';
}

class UiRootErrorDetail extends StatelessWidget {
  const UiRootErrorDetail({super.key, required this.detail, this.msgId = 0, this.reqId = ''});

  final String detail;
  final int msgId;
  final String reqId;

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
    final text = rootErrorCopyText(detail: detail, msgId: msgId, reqId: reqId);
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
