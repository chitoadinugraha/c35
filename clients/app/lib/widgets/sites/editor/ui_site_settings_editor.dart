import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/io_site_domain_buy_dialog.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_domain_section.dart';
import 'package:alienai_c35/widgets/sites/io_site_domain_dialogs.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

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
  int? _checkingDomainId;
  int? _fixingDomainId;
  Map<String, bool> _caps = Map<String, bool>.from(siteCapabilityDefaults);
  List<SiteDomain> _domains = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await widget.api.configGet(widget.siteIid);
      _caps = siteCapabilitiesParse(config.capabilitiesJson);
      _domains = await widget.api.domainList(widget.siteIid);
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

  Future<void> _refreshDomains() async {
    _domains = await widget.api.domainList(widget.siteIid);
    if (mounted) setState(() {});
  }

  Future<void> _addDomain() async {
    if (_domainsBusy || _domains.any(siteDomainPendingByo)) return;
    final host = await ioSiteDomainAddDialogOpen(context);
    if (host == null || !mounted || _domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      final row = widget.api.domainNew(widget.siteIid)..hostname = host;
      await widget.api.domainPut(widget.siteIid, row);
      await _refreshDomains();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _buyDomain() async {
    if (_domainsBusy) return;
    final bought = await ioSiteDomainBuyDialogOpen(context, api: widget.api, siteIid: widget.siteIid);
    if (!bought || !mounted) return;
    setState(() => _domainsBusy = true);
    try {
      await _refreshDomains();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _removeDomain(SiteDomain d) async {
    if (_domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      await widget.api.domainDelete(widget.siteIid, d);
      await _refreshDomains();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _verifyDomain(SiteDomain d) async {
    if (_domainsBusy || _checkingDomainId != null) return;
    if (siteDomainIsBought(d)) {
      await _runVerify(d);
      return;
    }
    await ioSiteDomainDnsDialogOpen(
      context,
      domain: d.hostname,
      errorMessage: d.verifyError.isNotEmpty ? d.verifyError : null,
      onCheck: () => _runVerify(d),
    );
  }

  Future<bool> _runVerify(SiteDomain d) async {
    setState(() => _checkingDomainId = d.id.toInt());
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
      if (mounted) setState(() => _checkingDomainId = null);
    }
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

  Widget _capToggle(String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
        value: _caps[key] ?? siteCapabilityDefault(key),
        activeThumbColor: _accent,
        onChanged: _savingCaps ? null : (v) => _saveCapability(key, v),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Capabilities', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Enable backend features for this site.', style: TextStyle(color: _muted, fontSize: 12)),
        _capToggle('commerce', 'Commerce (Orders & Products)'),
        _capToggle('booking', 'Booking (Objects tab)'),
        _capToggle('queue', 'Queue blocks'),
        _capToggle('attendance', 'Attendance (face enroll on Team)'),
        const SizedBox(height: 28),
        const Text('Domains', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('CNAME to $siteDomainCnameTarget (grey / DNS only)', style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        UiSiteDomainSection(
          domains: _domains,
          busy: _domainsBusy,
          checkingDomainId: _checkingDomainId,
          fixingDomainId: _fixingDomainId,
          onBuy: () => _buyDomain(),
          onAdd: () => _addDomain(),
          onVerify: (d) => _verifyDomain(d),
          onFixHttps: (d) => _fixHttps(d),
          onRemove: (d) => _removeDomain(d),
        ),
      ],
    );
  }
}
