import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:fixnum/fixnum.dart';

/// Grey CNAME target for custom site domains (not orange `alienai.id`).
const siteDomainCnameTarget = 'site.alienai.id';

bool siteDomainDnsVerified(SiteDomain d) => d.verifiedTsMs > Int64.ZERO;

enum SiteDomainTlsChip { pending, ready, failed, disabled }

SiteDomainTlsChip siteDomainTlsChip(String tlsStatus) => switch (tlsStatus.trim().toLowerCase()) {
      'ready' || 'active' => SiteDomainTlsChip.ready,
      'failed' => SiteDomainTlsChip.failed,
      'disabled' => SiteDomainTlsChip.disabled,
      _ => SiteDomainTlsChip.pending,
    };
