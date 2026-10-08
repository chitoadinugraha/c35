import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
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

/// Returns true when a domain was purchased.
Future<bool> ioSiteDomainBuyDialogOpen(BuildContext context, {required SiteApi api, required int siteIid}) async {
  final bought = await showDialog<bool>(
    context: context,
    builder: (ctx) => _SiteDomainBuyDialog(api: api, siteIid: siteIid),
  );
  return bought == true;
}

class _SiteDomainBuyDialog extends StatefulWidget {
  const _SiteDomainBuyDialog({required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<_SiteDomainBuyDialog> createState() => _SiteDomainBuyDialogState();
}

class _SiteDomainBuyDialogState extends State<_SiteDomainBuyDialog> {
  final _query = TextEditingController();
  Timer? _debounce;
  var _searching = false;
  var _hasSearched = false;
  var _buying = '';
  var _message = '';
  List<SiteDomainSearchHit> _hits = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => unawaited(_runSearch()));
  }

  Future<void> _runSearch() async {
    final q = siteDomainNormalizeHost(_query.text);
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _hits = const [];
          _hasSearched = false;
          _message = '';
        });
      }
      return;
    }
    setState(() {
      _searching = true;
      _message = '';
    });
    try {
      final found = await widget.api.domainSearch(widget.siteIid, q);
      if (!mounted) return;
      final names = <String>[
        for (final h in found)
          if (h.name.trim().isNotEmpty) h.name.trim().toLowerCase(),
      ];
      if (siteDomainHostLooksValid(q) && !names.contains(q)) names.insert(0, q);
      var rows = found;
      if (names.isNotEmpty) {
        try {
          final checked = await widget.api.domainCheck(widget.siteIid, names);
          if (!mounted) return;
          if (checked.isNotEmpty) rows = checked;
        } catch (e) {
          if (rows.isEmpty) rethrow;
        }
      }
      setState(() {
        _hits = rows;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = uiFriendlyError(e);
        _hasSearched = true;
        _hits = const [];
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  String _priceLine(SiteDomainSearchHit hit) {
    final cost = siteDomainPriceAmount(hit.registrationCost);
    if (cost.isEmpty) return '';
    final currency = hit.currency.trim().toUpperCase();
    if (currency.isEmpty) return 'site.domain.perYearAmount'.tr(namedArgs: {'cost': cost});
    return 'site.domain.perYear'.tr(namedArgs: {'currency': currency, 'cost': cost});
  }

  bool _taken(SiteDomainSearchHit hit) => !hit.registrable && hit.reason.trim() == 'domain_unavailable';

  String _subtitle(SiteDomainSearchHit hit) {
    final price = _priceLine(hit);
    if (hit.registrable && price.isNotEmpty) return price;
    if (_taken(hit)) return 'site.domain.taken'.tr();
    final reason = hit.reason.trim();
    if (reason.isEmpty || reason == 'extension_not_supported_via_api') return 'site.domain.unavailable'.tr();
    return reason;
  }

  Future<void> _buy(SiteDomainSearchHit hit) async {
    if (_buying.isNotEmpty) return;
    final price = _priceLine(hit);
    if (!hit.registrable || price.isEmpty) return;
    final currency = hit.currency.trim().toUpperCase();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialog,
        title: Text('site.domain.confirmBuyTitle'.tr(), style: const TextStyle(color: _text)),
        content: Text(
          'site.domain.confirmBuyBody'.tr(namedArgs: {'domain': hit.name, 'price': price}),
          style: const TextStyle(color: _text, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E16)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('site.domain.buy'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _buying = hit.name;
      _message = '';
    });
    try {
      final res = await widget.api.domainBuy(widget.siteIid, hit.name);
      if (!mounted) return;
      if (res.error.trim().isNotEmpty) {
        setState(() => _message = _buyError(res.error, currency));
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = _buyError(uiFriendlyError(e), currency));
    } finally {
      if (mounted) setState(() => _buying = '');
    }
  }

  String _buyError(String raw, String currency) {
    if (siteDomainInsufficientBalance(raw)) {
      final cur = currency.isEmpty ? 'site.domain.quotedCurrency'.tr() : currency;
      return 'site.domain.insufficientBalance'.tr(namedArgs: {'currency': cur});
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final loading = _searching || _buying.isNotEmpty;
    return AlertDialog(
      backgroundColor: _dialog,
      title: Text('site.domain.buy'.tr(), style: const TextStyle(color: _text)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              enabled: _buying.isEmpty,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: UiInputDecoration.of(context, hintText: 'site.domain.searchHint'.tr()),
              onChanged: (_) {
                if (_message.isNotEmpty) setState(() => _message = '');
                _scheduleSearch();
              },
              onSubmitted: (_) => unawaited(_runSearch()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
                          const SizedBox(height: 8),
                          Text(
                            _buying.isNotEmpty ? 'site.domain.buying'.tr() : 'site.domain.searching'.tr(),
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : _hits.isEmpty
                      ? Center(
                          child: Text(
                            _hasSearched && siteDomainNormalizeHost(_query.text).length >= 2 ? 'site.domain.noResults'.tr() : '',
                            style: const TextStyle(color: _muted, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _hits.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, i) => _row(_hits[i]),
                        ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_message, style: const TextStyle(color: _err, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
      ],
    );
  }

  Widget _row(SiteDomainSearchHit hit) {
    final price = _priceLine(hit);
    final canBuy = hit.registrable && price.isNotEmpty && _buying.isEmpty;
    final subtitle = _subtitle(hit);
    final bad = !hit.registrable;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.name, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: bad ? _err : _muted, fontSize: 12)),
                ],
              ),
            ),
            if (canBuy)
              TextButton(
                onPressed: () => unawaited(_buy(hit)),
                child: Text('site.domain.buy'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
