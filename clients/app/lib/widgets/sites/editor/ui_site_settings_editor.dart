import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/io_site_domain_dialogs.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _error = Color(0xFFF87171);

class UiSiteSettingsEditor extends StatefulWidget {
  const UiSiteSettingsEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final Future<void> Function()? onCapabilitiesSaved;

  @override
  State<UiSiteSettingsEditor> createState() => _UiSiteSettingsEditorState();
}

class _UiSiteSettingsEditorState extends State<UiSiteSettingsEditor> {
  var _loading = true;
  var _savingCaps = false;
  var _domainsBusy = false;
  int? _fixingDomainId;
  Map<String, bool> _caps = {for (final k in ['commerce', 'booking', 'queue']) k: true};
  final _domains = <String, SiteDomain>{};
  List<Map<String, String>> _domainRows = const [];
  List<TableDef> _defs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  TableDef _domainDef() =>
      widget.api.domainTableDef(_defs) ?? TableDef(collection: 'site.domain', primaryKey: 'site_iid,id');

  void _setDomains(List<SiteDomain> items) {
    final def = _domainDef();
    _domains
      ..clear()
      ..addEntries(items.map((d) {
        final cells = siteDomainCells(d);
        return MapEntry(siteRowKey(def, cells), d);
      }));
    _domainRows = _domains.values.map(siteDomainCells).toList(growable: false);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _defs = await widget.api.collectionDefs(siteIid: widget.siteIid);
      final config = await widget.api.configGet(widget.siteIid);
      _caps = siteCapabilitiesParse(config.capabilitiesJson);
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCapability(String key, bool value) async {
    if (_savingCaps) return;
    setState(() {
      _savingCaps = true;
      _caps = {..._caps, key: value};
    });
    try {
      await widget.api.configPut(widget.siteIid, capabilitiesJson: siteCapabilitiesEncode(_caps));
      await widget.onCapabilitiesSaved?.call();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      await _load();
    } finally {
      if (mounted) setState(() => _savingCaps = false);
    }
  }

  Future<void> _commitDomain(String rowKey, ColDef col, String value) async {
    if (_domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      final base = _domains[rowKey] ?? widget.api.domainNew(widget.siteIid);
      await widget.api.domainPut(widget.siteIid, siteDomainApplyCell(base, col, value));
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _addDomain() async {
    if (_domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      await widget.api.domainPut(widget.siteIid, widget.api.domainNew(widget.siteIid));
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _refreshDomains() async => _setDomains(await widget.api.domainList(widget.siteIid));

  Future<void> _verifyDomain(SiteDomain d) async {
    if (_domainsBusy) return;
    await ioSiteDomainDnsDialogOpen(
      context,
      domain: d.hostname,
      errorMessage: d.verifyError.isNotEmpty ? d.verifyError : null,
      onCheck: () async {
        setState(() => _domainsBusy = true);
        try {
          final res = await widget.api.domainVerify(widget.siteIid, d.id.toInt());
          await _refreshDomains();
          if (!mounted) return false;
          if (res.dnsVerified) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNS verified'), behavior: SnackBarBehavior.floating));
            return true;
          }
          final msg = res.error.isNotEmpty ? res.error : 'DNS verification failed';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
          return false;
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
          return false;
        } finally {
          if (mounted) setState(() => _domainsBusy = false);
        }
      },
    );
  }

  Future<void> _fixHttps(SiteDomain d) async {
    if (_fixingDomainId != null) return;
    setState(() => _fixingDomainId = d.id.toInt());
    try {
      final res = await widget.api.domainVerify(widget.siteIid, d.id.toInt(), forceTls: true);
      await _refreshDomains();
      if (!mounted) return;
      final tls = res.tlsStatus.trim();
      if (tls == 'ready' || tls == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HTTPS ready'), behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tls.isEmpty ? 'TLS sync requested' : 'TLS: $tls'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _fixingDomainId = null);
    }
  }

  Widget _domainStatusRow(String rowKey, double width) {
    final d = _domains[rowKey];
    if (d == null) return const SizedBox.shrink();
    final domainId = d.id.toInt();
    final dnsOk = siteDomainDnsVerified(d);
    final tls = siteDomainTlsChip(d.tlsStatus);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!dnsOk)
                  TextButton(
                    onPressed: _domainsBusy ? null : () => _verifyDomain(d),
                    child: const Text('Verify DNS'),
                  )
                else if (tls == SiteDomainTlsChip.failed)
                  TextButton(
                    onPressed: _fixingDomainId != null ? null : () => _fixHttps(d),
                    child: _fixingDomainId == domainId
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                        : const Text('Fix HTTPS'),
                  ),
                TextButton(
                  onPressed: _domainsBusy ? null : () => ioSiteDomainDnsDialogOpen(context, domain: d.hostname),
                  child: const Text('DNS steps'),
                ),
              ],
            ),
            if (dnsOk) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SiteDomainStatusChip(label: 'DNS verified', tone: _SiteDomainChipTone.ok),
                  switch (tls) {
                    SiteDomainTlsChip.ready => _SiteDomainStatusChip(label: 'HTTPS ready', tone: _SiteDomainChipTone.ok),
                    SiteDomainTlsChip.failed => _SiteDomainStatusChip(label: 'HTTPS failed', tone: _SiteDomainChipTone.bad),
                    SiteDomainTlsChip.disabled => _SiteDomainStatusChip(label: 'HTTPS cluster only', tone: _SiteDomainChipTone.muted),
                    SiteDomainTlsChip.pending => _SiteDomainStatusChip(label: 'HTTPS pending', tone: _SiteDomainChipTone.warn),
                  },
                ],
              ),
              if (d.tlsError.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(d.tlsError, style: const TextStyle(color: _error, fontSize: 12)),
              ],
            ] else if (d.verifyError.isNotEmpty) ...[
              Text(d.verifyError, style: const TextStyle(color: _error, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _capToggle(String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
        value: _caps[key] ?? true,
        activeThumbColor: _accent,
        onChanged: _savingCaps ? null : (v) => _saveCapability(key, v),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final domainDef = widget.api.domainTableDef(_defs);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Capabilities', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Enable backend features for this site.', style: TextStyle(color: _muted, fontSize: 12)),
        _capToggle('commerce', 'Commerce (Orders & Products)'),
        _capToggle('booking', 'Booking (Objects tab)'),
        _capToggle('queue', 'Queue blocks'),
        const SizedBox(height: 28),
        const Text('Domains', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('CNAME to $siteDomainCnameTarget (grey / DNS only)', style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        if (domainDef == null)
          const Text('No domain table definition', style: TextStyle(color: _muted))
        else
          UiTable(
            def: domainDef,
            rows: _domainRows,
            loading: _domainsBusy,
            onCellCommit: _commitDomain,
            onAddRow: _addDomain,
            rowBuilder: (scope) => [...scope.defaultTiles, _domainStatusRow(scope.rowKey, scope.tableWidth)],
          ),
      ],
    );
  }
}

enum _SiteDomainChipTone { ok, warn, bad, muted }

class _SiteDomainStatusChip extends StatelessWidget {
  const _SiteDomainStatusChip({required this.label, required this.tone});

  final String label;
  final _SiteDomainChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      _SiteDomainChipTone.ok => (
          const Color(0xFF14532D).withValues(alpha: 0.45),
          const Color(0xFF22C55E).withValues(alpha: 0.45),
          const Color(0xFF4ADE80),
          Icons.verified,
        ),
      _SiteDomainChipTone.warn => (
          const Color(0xFF713F12).withValues(alpha: 0.40),
          const Color(0xFFF59E0B).withValues(alpha: 0.45),
          const Color(0xFFFCD34D),
          Icons.hourglass_top,
        ),
      _SiteDomainChipTone.bad => (
          const Color(0xFF7F1D1D).withValues(alpha: 0.40),
          const Color(0xFFEF4444).withValues(alpha: 0.45),
          const Color(0xFFFCA5A5),
          Icons.error_outline,
        ),
      _SiteDomainChipTone.muted => (
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
