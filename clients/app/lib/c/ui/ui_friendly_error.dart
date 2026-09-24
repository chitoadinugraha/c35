class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

const uiConnectionProblem = 'Connection Problem';
const uiCannotConnectToAlienAi = 'Cannot connect to Alien AI';

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
      lower.contains('connection closed') ||
      lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('websocket') ||
      lower.contains('network is unreachable') ||
      lower == 'disconnected';
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
  if (lower.contains('websocketchannel') ||
      lower.contains('websocket') ||
      lower.contains('connection closed before full header') ||
      lower.contains('connection closed')) {
    return uiCannotConnectToAlienAi;
  }
  if (lower.contains('cluster offline') || lower.contains('space offline')) {
    return "Can't reach Alien AI right now. Check your internet connection and try again.";
  }
  if (lower.contains('agent starting / offline')) {
    return 'The local agent is still starting. Wait a moment and try again.';
  }
  if (lower.contains('no response from agent')) {
    return 'No response from Alien AI. Try again.';
  }
  if (lower.contains('empty response')) {
    return "Alien AI didn't return an answer. Please try again.";
  }
  if (lower.contains('gemini_api_key missing') || lower.contains('api key missing')) {
    return 'Alien AI is not configured yet. Please try again later.';
  }
  if (lower.contains('unauthorized') || lower.contains('invalid session')) {
    return 'Your session expired. Sign out and sign in again.';
  }
  if (lower.contains('5-hour allowance exhausted') || lower.contains('5h quota')) {
    return "You've reached your 5-hour quota allowance. Please top up your wallet balance or wait for the 5-hour window to reset.";
  }
  if (lower.contains('weekly allowance exhausted') || lower.contains('weekly quota')) {
    return "You've reached your weekly quota allowance. Please top up your wallet balance or wait for next week's quota reset.";
  }
  if (lower.contains('insufficient safe balance') || lower.contains('not enough balance or quota')) {
    return "Not enough balance or quota. Please top up your wallet balance to continue.";
  }
  if (lower.contains('quota exceeded')) {
    return "Quota limit reached. Please top up your wallet balance or wait for your quota to reset.";
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
