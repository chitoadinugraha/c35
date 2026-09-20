const alienIdMinLen = 7;
const alienIdMaxLen = 64;

String alienIdNormalize(String input) => input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');

String? alienIdFormatError(String alienId) {
  final id = alienIdNormalize(alienId.trim());
  if (id.isEmpty) return 'Alien ID required';
  if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(id)) return 'Only a-z, 0-9, _ and -';
  if (id.length < alienIdMinLen) return 'At least $alienIdMinLen characters';
  if (id.length > alienIdMaxLen) return 'At most $alienIdMaxLen characters';
  return null;
}

String alienIdHostLabel(String alienId) {
  final id = alienIdNormalize(alienId.trim());
  return id.isEmpty ? 'alienai.id/…' : '$id@alienai.id';
}
