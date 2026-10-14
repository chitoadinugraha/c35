import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_domain.dart';

/// Client-side TLS status polling after DNS verify (CSA publish-section parity).
class SiteDomainTlsPoll {
  SiteDomainTlsPoll({
    required this.api,
    required this.siteIid,
    required this.onTick,
  });

  final SiteApi api;
  final int siteIid;
  final Future<void> Function() onTick;

  static const _interval = Duration(seconds: 4);
  static const _maxTicks = 45;

  final Map<int, Timer> _timers = {};

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  void cancel(int domainId) {
    _timers.remove(domainId)?.cancel();
  }

  void startIfNeeded(int domainId, String tlsStatus) {
    final chip = siteDomainTlsChip(tlsStatus);
    if (chip == SiteDomainTlsChip.ready || chip == SiteDomainTlsChip.failed || chip == SiteDomainTlsChip.disabled) {
      cancel(domainId);
      return;
    }
    if (_timers.containsKey(domainId)) return;

    var ticks = 0;
    _timers[domainId] = Timer.periodic(_interval, (t) async {
      ticks++;
      if (ticks > _maxTicks) {
        t.cancel();
        _timers.remove(domainId);
        return;
      }
      try {
        await api.domainVerify(siteIid, domainId);
        await onTick();
      } catch (_) {}
    });
  }

  void syncFromDomains(List<SiteDomain> domains) {
    final ids = <int>{};
    for (final d in domains) {
      if (!siteDomainDnsVerified(d)) continue;
      final id = d.id.toInt();
      ids.add(id);
      startIfNeeded(id, d.tlsStatus);
    }
    for (final id in _timers.keys.toList()) {
      if (!ids.contains(id)) cancel(id);
    }
  }
}