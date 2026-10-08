class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

const uiConnectionProblem = 'Connection Problem';
const uiCannotConnectToAlienAi = 'Cannot connect to Alien AI';
const uiConnectionFailed = 'Connection failed';

bool uiIsRecoverableDeviceContextError(String raw) {
  final lower = raw.trim().toLowerCase();
  return lower.contains('device_iid is required') || lower.contains('device_iid required');
}

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
      lower.contains('cannot add event after closing') ||
      lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('websocket') ||
      lower.contains('network is unreachable') ||
      lower == 'disconnected' ||
      lower == 'connection failed';
}

bool uiIsTechnicalError(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  final lower = s.toLowerCase();
  if (lower.contains('gemini http') ||
      lower.contains('invalid_argument') ||
      lower.contains('failed_precondition') ||
      lower.contains('thought_signature') ||
      lower.contains('generativelanguage.googleapis.com') ||
      lower.contains('openai') ||
      lower.contains('anthropic') ||
      lower.contains('vertex ai') ||
      (lower.contains('bad request') && lower.contains('gemini'))) {
    return true;
  }
  if (s.contains('{\n') || (s.contains('"error"') && s.contains('{'))) return true;
  if (lower.contains('"status"') && (lower.contains('invalid') || lower.contains('internal'))) return true;
  if (RegExp(r'\bHTTP\s+\d{3}\b', caseSensitive: false).hasMatch(s)) return true;
  if (s.length > 220 && (s.contains('{') || s.contains('":'))) return true;
  return false;
}

bool uiIsQuotaError(Object error) {
  final s = error.toString().toLowerCase();
  if (s.isEmpty) return false;
  return s.contains('quota') ||
      s.contains('allowance exhausted') ||
      s.contains('freemium daily limit') ||
      s.contains('free daily limit') ||
      s.contains('daily message limit') ||
      s.contains('insufficient safe balance') ||
      s.contains('not enough balance or quota') ||
      s.contains('not enough balance') ||
      s.contains('reached your 5-hour') ||
      s.contains('reached your weekly') ||
      s.contains('out of quota');
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
  if (lower.contains('cannot add event after closing') || lower == 'disconnected' || lower.contains('connection failed')) {
    return uiConnectionFailed;
  }
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
  if (lower.contains('freemium daily limit') || lower.contains('daily message limit')) {
    return "You've reached your free daily message limit. Upgrade your plan to continue.";
  }
  if (lower.contains('5-hour allowance exhausted') || lower.contains('5h quota')) {
    return "You've reached your 5-hour quota allowance. Upgrade your plan or wait for the window to reset.";
  }
  if (lower.contains('weekly allowance exhausted') || lower.contains('weekly quota')) {
    return "You've reached your weekly quota allowance. Upgrade your plan or wait for next week's quota reset.";
  }
  if (lower.contains('insufficient safe balance') || lower.contains('not enough balance or quota') || lower.contains('not enough balance')) {
    return "You're out of quota. Upgrade your plan or top up your balance to continue.";
  }
  if (lower.contains('billing quota exhausted') ||
      lower.contains('quota exceeded') ||
      lower.contains('out of quota') ||
      lower.contains('scoped quota exceeded') ||
      lower.contains('bot message quota exceeded')) {
    return "You're out of quota. Upgrade your plan or wait for your quota to reset.";
  }
  if (uiIsRecoverableDeviceContextError(s)) {
    return fallback;
  }
  if (uiIsTechnicalError(s)) return fallback;
  if (RegExp(r'https?://|\d{1,3}(?:\.\d{1,3}){3}|localhost|status=\d|errno|socketexception').hasMatch(lower)) {
    if (lower.contains('timeout') || lower.contains('timed out')) return 'Request timed out. Check your internet and try again.';
    if (lower.contains('refused') || lower.contains('failed host lookup') || lower.contains('unreachable')) {
      return "Can't reach Alien AI right now. Check your internet and try again.";
    }
    return fallback;
  }
  if (s.length > 220 || s.contains('{') || s.contains('\n')) return fallback;
  return s;
}

String uiApiErrorMessage(String serverMessage, {required String fallback}) {
  final trimmed = serverMessage.trim();
  if (trimmed.isEmpty) return fallback;
  return uiFriendlyError(trimmed, fallback: fallback);
}

String uiPromptErrorMessage(String raw) => uiFriendlyError(raw.trim(), fallback: "Something went wrong. Please try again.");
