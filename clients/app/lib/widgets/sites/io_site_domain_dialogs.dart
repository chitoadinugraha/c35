import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _errorColor = Color(0xFFF87171);
const _dialog = Color(0xFF111114);

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
      setState(() => _errorText = 'site.domain.cnameNotFound'.tr(namedArgs: {'target': siteDomainCnameTarget}));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apex = siteDomainIsApex(widget.domain);
    return AlertDialog(
      backgroundColor: _dialog,
      title: Text('site.domain.dnsTitle'.tr(), style: const TextStyle(color: _text)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'site.domain.dnsBody'.tr(namedArgs: {'domain': widget.domain, 'target': siteDomainCnameTarget}),
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 14),
            _DnsRecordRow(label: 'site.domain.dnsType'.tr(), value: 'CNAME'),
            const SizedBox(height: 8),
            _DnsRecordRow(label: 'site.domain.dnsHost'.tr(), value: widget.domain),
            const SizedBox(height: 8),
            _DnsRecordRow(label: 'site.domain.dnsTarget'.tr(), value: siteDomainCnameTarget),
            if (apex) ...[
              const SizedBox(height: 10),
              Text(
                'site.domain.dnsApexHint'.tr(namedArgs: {'target': siteDomainCnameTarget}),
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_errorText, style: const TextStyle(color: _errorColor, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        if (widget.onCheck != null)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E16)),
            onPressed: _checking ? null : () => unawaited(_runCheck()),
            child: _checking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('site.domain.verify'.tr()),
          ),
      ],
    );
  }
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
                tooltip: 'site.domain.copyTooltip'.tr(),
                icon: const Icon(Icons.copy, size: 16, color: _muted),
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              ),
            ],
          ),
        ),
      );
}

/// Typed confirm for bought domains; simple dialog for BYO.
Future<bool> ioSiteDomainRemoveConfirmOpen(BuildContext context, {required SiteDomain domain}) async {
  if (siteDomainIsBought(domain)) {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => _SiteDomainRemoveTypedDialog(hostname: domain.hostname),
        ) ==
        true;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _dialog,
      title: Text('site.domain.removeTitle'.tr(), style: const TextStyle(color: _text)),
      content: Text(
        'site.domain.removeBodySimple'.tr(namedArgs: {'domain': domain.hostname}),
        style: const TextStyle(color: _muted, fontSize: 13),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: _errorColor),
          child: Text('common.delete'.tr()),
        ),
      ],
    ),
  );
  return ok == true;
}

class _SiteDomainRemoveTypedDialog extends StatefulWidget {
  const _SiteDomainRemoveTypedDialog({required this.hostname});

  final String hostname;

  @override
  State<_SiteDomainRemoveTypedDialog> createState() => _SiteDomainRemoveTypedDialogState();
}

class _SiteDomainRemoveTypedDialogState extends State<_SiteDomainRemoveTypedDialog> {
  final _input = TextEditingController();

  String get _expected => siteDomainNormalizeHost(widget.hostname);

  bool get _matches => siteDomainNormalizeHost(_input.text) == _expected;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _dialog,
        title: Text('site.domain.removeTitle'.tr(), style: const TextStyle(color: _text)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'site.domain.removeBody'.tr(namedArgs: {'domain': _expected}),
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _input,
                autofocus: true,
                autocorrect: false,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  labelText: 'site.domain.domainLabel'.tr(),
                  labelStyle: const TextStyle(color: _muted),
                  hintText: _expected,
                  hintStyle: const TextStyle(color: _muted),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _accent)),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_matches) Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: _matches ? () => Navigator.pop(context, true) : null,
            style: FilledButton.styleFrom(backgroundColor: _errorColor, foregroundColor: Colors.white),
            child: Text('common.remove'.tr()),
          ),
        ],
      );
}
