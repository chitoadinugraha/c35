/// Guest storefront Alien AI assistant settings in draft `meta.ai_assistant`.
class SiteAiAssistantDraft {
  const SiteAiAssistantDraft({
    this.chatEnabled = true,
    this.callEnabled = false,
    this.chatIntro = '',
    this.chatPlaceholder = 'Ask Alien AI...',
    this.callIntro = '',
    this.configured = false,
  });

  static const legacyDefaults = SiteAiAssistantDraft(configured: false);

  final bool chatEnabled;
  final bool callEnabled;
  final String chatIntro;
  final String chatPlaceholder;
  final String callIntro;
  final bool configured;

  bool get featureChatEnabled => configured ? chatEnabled : true;

  bool get featureCallEnabled => configured ? callEnabled : false;

  SiteAiAssistantDraft copyWith({
    bool? chatEnabled,
    bool? callEnabled,
    String? chatIntro,
    String? chatPlaceholder,
    String? callIntro,
    bool? configured,
  }) =>
      SiteAiAssistantDraft(
        chatEnabled: chatEnabled ?? this.chatEnabled,
        callEnabled: callEnabled ?? this.callEnabled,
        chatIntro: chatIntro ?? this.chatIntro,
        chatPlaceholder: chatPlaceholder ?? this.chatPlaceholder,
        callIntro: callIntro ?? this.callIntro,
        configured: configured ?? this.configured,
      );
}

SiteAiAssistantDraft siteAiAssistantRead(Object? raw) {
  if (raw is! Map) return SiteAiAssistantDraft.legacyDefaults;
  final map = raw.map((k, v) => MapEntry(k.toString(), v));
  if (map.isEmpty) return SiteAiAssistantDraft.legacyDefaults;

  var chatEnabled = true;
  if (map.containsKey('chat_enabled')) {
    chatEnabled = map['chat_enabled'] == true;
  } else if (map['floating_bubble'] is bool) {
    chatEnabled = map['floating_bubble'] as bool;
  }

  final callEnabled = map['call_enabled'] == true;
  final placeholderRaw = map['chat_placeholder']?.toString().trim() ?? '';
  return SiteAiAssistantDraft(
    chatEnabled: chatEnabled,
    callEnabled: callEnabled,
    chatIntro: map['chat_intro']?.toString() ?? '',
    chatPlaceholder: placeholderRaw.isNotEmpty ? placeholderRaw : 'Ask Alien AI...',
    callIntro: map['call_intro']?.toString() ?? '',
    configured: true,
  );
}

Map<String, dynamic> siteAiAssistantToJson(SiteAiAssistantDraft draft) => {
      'chat_enabled': draft.chatEnabled,
      'call_enabled': draft.callEnabled,
      'floating_bubble': draft.chatEnabled,
      'chat_intro': draft.chatIntro,
      'chat_placeholder': draft.chatPlaceholder,
      'call_intro': draft.callIntro,
    };