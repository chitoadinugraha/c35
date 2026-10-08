import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _err = Color(0xFFF87171);
const _panel = Color(0xFF18181B);
const _dialog = Color(0xFF111114);

class UiSiteDomainSection extends StatelessWidget {
  const UiSiteDomainSection({
    super.key,
    required this.domains,
    required this.busy,
    required this.checkingDomainId,
    required this.fixingDomainId,
    required this.onBuy,
    required this.onAdd,
    required this.onVerify,
    required this.onFixHttps,
    required this.onRemove,
  });

  final List<SiteDomain> domains;
  final bool busy;
  final int? checkingDomainId;
  final int? fixingDomainId;
  final VoidCallback onBuy;
  final VoidCallback onAdd;
  final ValueChanged<SiteDomain> onVerify;
  final ValueChanged<SiteDomain> onFixHttps;
  final ValueChanged<SiteDomain> onRemove;

  bool get _pendingByo => domains.any(siteDomainPendingByo);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final domain in domains) ...[
          _DomainCard(
            domain: domain,
            busy: busy,
            checking: checkingDomainId == domain.id.toInt(),
            fixing: fixingDomainId == domain.id.toInt(),
            actionsLocked: checkingDomainId != null || fixingDomainId != null,
            onVerify: () => onVerify(domain),
            onFixHttps: () => onFixHttps(domain),
            onRemove: () => onRemove(domain),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: busy ? null : onBuy,
              icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: _accent),
              label: Text('site.domain.buy'.tr(), style: const TextStyle(color: _accent)),
            ),
            TextButton.icon(
              onPressed: busy || _pendingByo ? null : onAdd,
              icon: Icon(Icons.add, size: 16, color: busy || _pendingByo ? _muted : _accent),
              label: Text('site.domain.add'.tr(), style: TextStyle(color: busy || _pendingByo ? _muted : _accent)),
            ),
          ],
        ),
        if (_pendingByo)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('site.domain.pendingLimit'.tr(), style: const TextStyle(color: _muted, fontSize: 12)),
          ),
      ],
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.domain,
    required this.busy,
    required this.checking,
    required this.fixing,
    required this.actionsLocked,
    required this.onVerify,
    required this.onFixHttps,
    required this.onRemove,
  });

  final SiteDomain domain;
  final bool busy;
  final bool checking;
  final bool fixing;
  final bool actionsLocked;
  final VoidCallback onVerify;
  final VoidCallback onFixHttps;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final dnsOk = siteDomainDnsVerified(domain);
    final tls = siteDomainTlsChip(domain.tlsStatus);
    final mail = domain.mailStatus.trim().toLowerCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(domain.hostname, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                if (!dnsOk)
                  TextButton(
                    onPressed: busy || actionsLocked ? null : onVerify,
                    child: checking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                        : Text('site.domain.verify'.tr()),
                  )
                else if (tls == SiteDomainTlsChip.failed)
                  TextButton(
                    onPressed: actionsLocked ? null : onFixHttps,
                    child: fixing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                        : Text('site.domain.fixHttps'.tr()),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16, color: _muted),
                  onPressed: busy ? null : () => _confirmRemove(context),
                ),
              ],
            ),
            if (!dnsOk) ...[
              Text(_pendingHint(), style: const TextStyle(color: _muted, fontSize: 12)),
              if (domain.verifyError.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(domain.verifyError, style: const TextStyle(color: _err, fontSize: 12)),
              ],
            ] else ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusChip(label: 'site.domain.dnsVerified'.tr(), tone: _ChipTone.ok),
                  switch (tls) {
                    SiteDomainTlsChip.ready => _StatusChip(label: 'site.domain.httpsReady'.tr(), tone: _ChipTone.ok),
                    SiteDomainTlsChip.failed => _StatusChip(label: 'site.domain.httpsFailed'.tr(), tone: _ChipTone.bad),
                    SiteDomainTlsChip.disabled => _StatusChip(label: 'site.domain.httpsDisabled'.tr(), tone: _ChipTone.muted),
                    SiteDomainTlsChip.pending => _StatusChip(label: 'site.domain.httpsPending'.tr(), tone: _ChipTone.warn),
                  },
                  if (mail == 'ready') _StatusChip(label: 'site.domain.emailReady'.tr(), tone: _ChipTone.ok),
                ],
              ),
              if (tls == SiteDomainTlsChip.failed && domain.tlsError.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(domain.tlsError, style: const TextStyle(color: _err, fontSize: 12)),
              ],
              if (mail == 'failed') ...[
                const SizedBox(height: 6),
                Text(
                  domain.mailError.trim().isEmpty ? 'site.domain.emailFailed'.tr() : domain.mailError,
                  style: const TextStyle(color: _err, fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _pendingHint() {
    if (siteDomainIsBought(domain)) return 'site.domain.dnsSetup'.tr();
    final left = siteDomainByoTimeLeft(domain);
    if (left == Duration.zero) {
      return 'site.domain.verifyWithinMinutes'.tr(namedArgs: {'minutes': '0'});
    }
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    if (hours > 0) {
      return 'site.domain.verifyWithinHours'.tr(namedArgs: {'hours': '$hours', 'minutes': '$minutes'});
    }
    return 'site.domain.verifyWithinMinutes'.tr(namedArgs: {'minutes': '${left.inMinutes}'});
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialog,
        title: Text('site.domain.removeTitle'.tr(), style: const TextStyle(color: _text)),
        content: Text(
          'site.domain.removeBody'.tr(namedArgs: {'domain': domain.hostname}),
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _err),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (ok == true) onRemove();
  }
}

Future<String?> ioSiteDomainAddDialogOpen(BuildContext context) => showDialog<String>(
      context: context,
      builder: (ctx) => const _AddDomainDialog(),
    );

class _AddDomainDialog extends StatefulWidget {
  const _AddDomainDialog();

  @override
  State<_AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<_AddDomainDialog> {
  final _input = TextEditingController();
  var _message = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final host = siteDomainNormalizeHost(_input.text);
    if (!siteDomainHostLooksValid(host)) {
      setState(() => _message = 'site.domain.invalidHostname'.tr());
      return;
    }
    Navigator.pop(context, host);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _dialog,
        title: Text('site.domain.addTitle'.tr(), style: const TextStyle(color: _text)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _input,
                autofocus: true,
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: UiInputDecoration.of(context, labelText: 'site.domain.hostname'.tr(), hintText: 'site.domain.hostnameHint'.tr()),
                onSubmitted: (_) => _submit(),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_message, style: const TextStyle(color: _err, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E16)),
            onPressed: _submit,
            child: Text('site.domain.add'.tr()),
          ),
        ],
      );
}

enum _ChipTone { ok, warn, bad, muted }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      _ChipTone.ok => (
          const Color(0xFF14532D).withValues(alpha: 0.45),
          const Color(0xFF22C55E).withValues(alpha: 0.45),
          const Color(0xFF4ADE80),
          Icons.verified,
        ),
      _ChipTone.warn => (
          const Color(0xFF713F12).withValues(alpha: 0.40),
          const Color(0xFFF59E0B).withValues(alpha: 0.45),
          const Color(0xFFFCD34D),
          Icons.hourglass_top,
        ),
      _ChipTone.bad => (
          const Color(0xFF7F1D1D).withValues(alpha: 0.40),
          const Color(0xFFEF4444).withValues(alpha: 0.45),
          const Color(0xFFFCA5A5),
          Icons.error_outline,
        ),
      _ChipTone.muted => (
          const Color(0xFF27272A),
          _border,
          _muted,
          Icons.info_outline,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
