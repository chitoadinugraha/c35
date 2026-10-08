const platformSiteAlienId = 'alienai';

/// True when [id] is the reserved Alien AI platform site handle.
bool isPlatformSiteAlienId(String? id) {
  final raw = (id ?? '').trim();
  if (raw.isEmpty) return false;
  if (raw.length != platformSiteAlienId.length) return false;
  return raw.toLowerCase() == platformSiteAlienId;
}
