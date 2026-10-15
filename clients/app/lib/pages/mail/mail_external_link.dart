import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> confirmAndLaunchMailExternalUrl(BuildContext context, Uri uri) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.open_in_new_rounded, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Buka Tautan Luar'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anda akan meninggalkan Alien AI dan membuka tautan berikut di browser:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: SelectableText(
              uri.toString(),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pastikan domain tujuan aman sebelum memasukkan data atau kredensial.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.launch_rounded, size: 16),
          label: const Text('Buka Tautan'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

bool mailExternalUrlSchemeAllowed(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https' || scheme == 'mailto';
}
