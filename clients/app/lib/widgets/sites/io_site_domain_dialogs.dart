import 'dart:async';

import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _errorColor = Color(0xFFF87171);

Future<void> ioSiteDomainDnsDialogOpen(
  BuildContext context, {
  required String domain,
  Future<bool> Function()? onCheck,
  String? errorMessage,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => _SiteDomainDnsDialog(domain: domain, onCheck: onCheck, errorMessage: errorMessage),
    );

class _SiteDomainDnsDialog extends StatefulWidget {
  const _SiteDomainDnsDialog({required this.domain, this.onCheck, this.errorMessage});

  final String domain;
  final Future<bool> Function()? onCheck;
  final String? errorMessage;

  @override
  State<_SiteDomainDnsDialog> createState() => _SiteDomainDnsDialogState();
}

class _SiteDomainDnsDialogState extends State<_SiteDomainDnsDialog> {
  var _checking = false;
  late var _errorText = widget.errorMessage ?? '';

  Future<void> _runCheck() async {
    if (_checking || widget.onCheck == null) return;
    setState(() {
      _checking = true;
      _errorText = '';
    });
    try {
      final ok = await widget.onCheck!();
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        return;
      }
      setState(() => _errorText = 'CNAME not found. Point your domain to $siteDomainCnameTarget and try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF111114),
        title: const Text('DNS setup', style: TextStyle(color: _text)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a CNAME record so $siteDomainCnameTarget serves your site for ${widget.domain}.',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _DnsRecordRow(label: 'Type', value: 'CNAME'),
              const SizedBox(height: 8),
              _DnsRecordRow(label: 'Host', value: widget.domain),
              const SizedBox(height: 8),
              _DnsRecordRow(label: 'Target', value: siteDomainCnameTarget),
              if (_errorText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorText, style: const TextStyle(color: _errorColor, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _checking ? null : () => Navigator.pop(context), child: const Text('Close')),
          if (widget.onCheck != null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E16)),
              onPressed: _checking ? null : () => unawaited(_runCheck()),
              child: _checking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify DNS'),
            ),
        ],
      );
}

class _DnsRecordRow extends StatelessWidget {
  const _DnsRecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
          color: const Color(0xFF18181B),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(label, style: const TextStyle(color: _muted, fontSize: 11))),
              Expanded(
                child: SelectableText(value, style: const TextStyle(color: _text, fontSize: 12, fontFamily: 'monospace')),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, size: 16, color: _muted),
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              ),
            ],
          ),
        ),
      );
}
