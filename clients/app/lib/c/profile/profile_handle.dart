const profileAlienDomain = 'alienai.id';
const _alienSuffix = '@$profileAlienDomain';

enum AuthLoginKind { alienId, email, phone }

String profileAlienAddress(String handle) {
  var id = handle.trim();
  if (id.startsWith('@')) id = id.substring(1);
  if (id.isEmpty) return '@$profileAlienDomain';
  return '$id@$profileAlienDomain';
}

String? authPhoneNormalize(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s.contains('@')) return null;
  var digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('0') && digits.length >= 10 && digits.length <= 13) digits = '62${digits.substring(1)}';
  if (digits.length < 8 || digits.length > 15) return null;
  return digits;
}

AuthLoginKind authLoginKind(String raw) {
  final trimmed = raw.trim();
  if (trimmed.contains('@') && !trimmed.startsWith('@') && !trimmed.toLowerCase().endsWith(_alienSuffix)) return AuthLoginKind.email;
  if (authPhoneNormalize(trimmed) != null) return AuthLoginKind.phone;
  return AuthLoginKind.alienId;
}

String authLoginNormalize(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final kind = authLoginKind(trimmed);
  if (kind == AuthLoginKind.email) return trimmed.toLowerCase();
  if (kind == AuthLoginKind.phone) return authPhoneNormalize(trimmed)!;
  var id = trimmed;
  if (id.toLowerCase().endsWith(_alienSuffix)) id = id.substring(0, id.length - _alienSuffix.length);
  if (id.startsWith('@')) id = id.substring(1);
  return id.toLowerCase();
}

String? authLoginAlienSuffix(String raw) => authLoginKind(raw) == AuthLoginKind.alienId ? '@$profileAlienDomain' : null;

bool authLoginIsEmailOrPhone(String raw) => authLoginKind(raw) == AuthLoginKind.email || authLoginKind(raw) == AuthLoginKind.phone;
