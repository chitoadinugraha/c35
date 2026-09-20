class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

const uiConnectionProblem = 'Connection Problem';

bool uiIsConnectionError(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) return false;
  return lower.contains('cluster offline') ||
      lower.contains('space offline') ||
      lower.contains('agent starting / offline') ||
      lower.contains('no response from agent') ||
      lower.contains('request failed') ||
      lower.contains('request timed out') ||
      lower.contains('timeoutexception') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('network is unreachable');
}

String uiReferralError(Object error, {required String fallback}) {
  var s = error.toString();
  if (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
  s = s.trim();
  if (s.isEmpty) return fallback;
  if (uiIsConnectionError(s)) return uiConnectionProblem;
  return uiFriendlyError(error, fallback: fallback);
}

String uiFriendlyError(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  var s = error.toString();
  if (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
  s = s.trim();
  if (s.isEmpty) return fallback;
  final lower = s.toLowerCase();
  if (lower.contains('cluster offline') || lower.contains('space offline')) {
    return "Can't reach Alien AI right now. Check your internet connection and try again.";
  }
  if (lower.contains('agent starting / offline')) {
    return 'The local agent is still starting. Wait a moment and try again.';
  }
  if (lower.contains('no response from agent')) {
    return 'No response from Alien AI. Try again.';
  }
  if (lower.contains('unauthorized') || lower.contains('invalid session')) {
    return 'Your session expired. Sign out and sign in again.';
  }
  if (RegExp(r'https?://|\d{1,3}(?:\.\d{1,3}){3}|localhost|status=\d|errno|socketexception').hasMatch(lower)) {
    if (lower.contains('timeout') || lower.contains('timed out')) return 'Request timed out. Check your internet and try again.';
    if (lower.contains('refused') || lower.contains('failed host lookup') || lower.contains('unreachable')) {
      return "Can't reach Alien AI right now. Check your internet and try again.";
    }
    return fallback;
  }
  return s;
}

String uiApiErrorMessage(String serverMessage, {required String fallback}) {
  final trimmed = serverMessage.trim();
  if (trimmed.isEmpty) return fallback;
  return uiFriendlyError(trimmed, fallback: fallback);
}

String uiPromptErrorMessage(String raw) => uiFriendlyError(raw.trim(), fallback: "Something went wrong. Please try again.");
