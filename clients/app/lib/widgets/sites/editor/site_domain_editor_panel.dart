import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/c/site/site_domain_tls_poll.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/io_site_domain_buy_dialog.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_domain_section.dart';
import 'package:alienai_c35/widgets/sites/io_site_domain_dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Shared domain list + verify/buy flow for site editor (Publish primary).
class UiSiteDomainPanel extends StatefulWidget {
  const UiSiteDomainPanel({
    super.key,
    required this.api,
    required this.siteIid,
    this.showCnameHint = true,
  });

  final SiteApi api;
  final int siteIid;
  final bool showCnameHint;

  @override
  State<UiSiteDomainPanel> createState() => _UiSiteDomainPanelState();
}

class _UiSiteDomainPanelState extends State<UiSiteDomainPanel> {
  var _loading = true;
  var _domainsBusy = false;
  int? _checkingDomainId;
  int? _fixingDomainId;
  List<SiteDomain> _domains = const [];
  SiteDomainTlsPoll? _tlsPoll;

  @override
  void initState() {
    super.initState();
    _tlsPoll = SiteDomainTlsPoll(api: widget.api, siteIid: widget.siteIid, onTick: _refreshDomains);
    unawaited(_load());
  }

  @override
  void dispose() {
    _tlsPoll?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _domains = await widget.api.domainList(widget.siteIid);
      _tlsPoll?.syncFromDomains(_domains);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDomains() async {
    _domains = await widget.api.domainList(widget.siteIid);
    _tlsPoll?.syncFromDomains(_domains);
    if (mounted) setState(() {});
  }

  SiteDomain? _findByHostname(String host) {
    final want = siteDomainNormalizeHost(host);
    for (final d in _domains) {
      if (siteDomainNormalizeHost(d.hostname) == want) return d;
    }
    return null;
  }

  Future<void> _openDnsDialog(SiteDomain d) async {
    await ioSiteDomainDnsDialogOpen(
      context,
      domain: d.hostname,
      errorMessage: d.verifyError.isNotEmpty ? d.verifyError : null,
      onCheck: () => _runVerify(d),
    );
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
      if (!mounted) return;
      final added = _findByHostname(host);
      if (added != null && siteDomainIsByo(added)) {
        await _openDnsDialog(added);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _removeDomain(SiteDomain d) async {
    if (_domainsBusy) return;
    final ok = await ioSiteDomainRemoveConfirmOpen(context, domain: d);
    if (!ok || !mounted) return;
    setState(() => _domainsBusy = true);
    try {
      _tlsPoll?.cancel(d.id.toInt());
      await widget.api.domainDelete(widget.siteIid, d);
      await _refreshDomains();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
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
    await _openDnsDialog(d);
  }

  Future<bool> _runVerify(SiteDomain d) async {
    setState(() => _checkingDomainId = d.id.toInt());
    try {
      final res = await widget.api.domainVerify(widget.siteIid, d.id.toInt());
      await _refreshDomains();
      if (!mounted) return false;
      if (res.dnsVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('site.domain.dnsVerified'.tr()), behavior: SnackBarBehavior.floating),
        );
        _tlsPoll?.startIfNeeded(d.id.toInt(), res.tlsStatus);
        return true;
      }
      final msg = res.error.isNotEmpty
          ? res.error
          : 'site.domain.cnameNotFound'.tr(namedArgs: {'target': siteDomainCnameTarget});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('site.domain.httpsReady'.tr()), behavior: SnackBarBehavior.floating),
        );
        _tlsPoll?.cancel(d.id.toInt());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tls.isEmpty ? 'site.domain.httpsPending'.tr() : 'TLS: $tls'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _tlsPoll?.startIfNeeded(d.id.toInt(), tls);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _fixingDomainId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showCnameHint) ...[
          Text(
            'site.domain.cnameHint'.tr(namedArgs: {'target': siteDomainCnameTarget}),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        UiSiteDomainSection(
          domains: _domains,
          busy: _domainsBusy,
          checkingDomainId: _checkingDomainId,
          fixingDomainId: _fixingDomainId,
          onBuy: _buyDomain,
          onAdd: _addDomain,
          onVerify: _verifyDomain,
          onDnsInstructions: _openDnsDialog,
          onFixHttps: _fixHttps,
          onRemove: _removeDomain,
        ),
      ],
    );
  }
}
