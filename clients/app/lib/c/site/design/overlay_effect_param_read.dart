/// Safe reads from overlay effect param maps (values may be bool, int, double).
int overlayEffectParamInt(Map<String, Object?> params, String key, int fallback) {
  final v = params[key];
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double overlayEffectParamDouble(Map<String, Object?> params, String key, double fallback) {
  final v = params[key];
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool overlayEffectParamBool(Map<String, Object?> params, String key, bool fallback) {
  final v = params[key];
  if (v is bool) return v;
  if (v == true || v == 'true' || v == 1 || v == '1') return true;
  if (v == false || v == 'false' || v == 0 || v == '0') return false;
  return fallback;
}

String overlayEffectParamString(Map<String, Object?> params, String key, String fallback) {
  final v = params[key];
  if (v is String) return v;
  if (v != null) return v.toString();
  return fallback;
}

num overlayEffectParamNum(Object? value, {required num fallback}) {
  if (value is num) return value;
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
