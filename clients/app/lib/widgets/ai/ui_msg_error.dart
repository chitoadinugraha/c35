import 'package:flutter/material.dart';

class UiMsgError extends StatelessWidget {
  const UiMsgError({super.key, required this.message, this.detail, this.onRetry, this.retrying = false});

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFF87171)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFFF4F4F5))),
                    if (detail != null && detail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: SelectableText(
                            detail!.trim(),
                            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFA1A1AA), fontFamily: 'Consolas'),
                          ),
                        ),
                      ),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: retrying ? null : onRetry,
                        icon: retrying
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399)))
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(retrying ? 'Retrying…' : 'Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF34D399),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      );
}
