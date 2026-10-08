import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:fixnum/fixnum.dart';

/// Grey CNAME target for custom site domains (not orange `alienai.id`).
const siteDomainCnameTarget = 'site.alienai.id';

bool siteDomainDnsVerified(SiteDomain d) => d.verifiedTsMs > Int64.ZERO;

bool siteDomainIsBought(SiteDomain d) => d.source.trim().toLowerCase() == 'bought';

/// Empty source is bring-your-own, same as an explicit `byo` row.
bool siteDomainIsByo(SiteDomain d) {
  final s = d.source.trim().toLowerCase();
  return s.isEmpty || s == 'byo';
}

bool siteDomainPendingByo(SiteDomain d) => siteDomainIsByo(d) && !siteDomainDnsVerified(d);

/// Time left in the 24h BYO verify window. Zero when the window has passed.
Duration siteDomainByoTimeLeft(SiteDomain d, [DateTime? now]) {
  final created = d.createdTsMs.toInt();
  final clock = now ?? DateTime.now();
  if (created <= 0) return const Duration(hours: 24);
  final end = DateTime.fromMillisecondsSinceEpoch(created).add(const Duration(hours: 24));
  final left = end.difference(clock);
  if (left.isNegative) return Duration.zero;
  return left;
}

String siteDomainNormalizeHost(String raw) {
  var s = raw.trim().toLowerCase();
  s = s.replaceFirst(RegExp(r'^https?://'), '');
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(0, slash);
  s = s.replaceAll(RegExp(r'\s+'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

bool siteDomainHostLooksValid(String host) {
  if (host.length < 4 || host.length > 253 || !host.contains('.')) return false;
  if (host.startsWith('.') || host.endsWith('.') || host.contains('..')) return false;
  return RegExp(r'^[a-z0-9.-]+$').hasMatch(host);
}

/// One quote amount, two decimal places. Empty when the registrar sent no cost.
String siteDomainPriceAmount(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final n = num.tryParse(t);
  if (n == null) return t;
  return n.toStringAsFixed(2);
}

bool siteDomainInsufficientBalance(String err) {
  final s = err.toLowerCase();
  return s.contains('insufficient_balance') || s.contains('insufficient balance');
}

enum SiteDomainTlsChip { pending, ready, failed, disabled }

SiteDomainTlsChip siteDomainTlsChip(String tlsStatus) => switch (tlsStatus.trim().toLowerCase()) {
      'ready' || 'active' => SiteDomainTlsChip.ready,
      'failed' => SiteDomainTlsChip.failed,
      'disabled' => SiteDomainTlsChip.disabled,
      _ => SiteDomainTlsChip.pending,
    };
