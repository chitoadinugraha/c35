/// Guest storefront Alien AI assistant settings in draft `meta.ai_assistant`.
class SiteAiAssistantDraft {
  const SiteAiAssistantDraft({
    this.chatEnabled = true,
    this.callEnabled = false,
    this.chatTitle = '',
    this.chatIntro = '',
    this.chatPlaceholder = '',
    this.callIntro = '',
    this.showPoweredBy = true,
    this.configured = false,
  });

  static const legacyDefaults = SiteAiAssistantDraft(configured: false);

  final bool chatEnabled;
  final bool callEnabled;
  final String chatTitle;
  final String chatIntro;
  final String chatPlaceholder;
  final String callIntro;
  final bool showPoweredBy;
  final bool configured;

  bool get featureChatEnabled => configured ? chatEnabled : true;

  bool get featureCallEnabled => configured ? callEnabled : false;

  SiteAiAssistantDraft copyWith({
    bool? chatEnabled,
    bool? callEnabled,
    String? chatTitle,
    String? chatIntro,
    String? chatPlaceholder,
    String? callIntro,
    bool? showPoweredBy,
    bool? configured,
  }) =>
      SiteAiAssistantDraft(
        chatEnabled: chatEnabled ?? this.chatEnabled,
        callEnabled: callEnabled ?? this.callEnabled,
        chatTitle: chatTitle ?? this.chatTitle,
        chatIntro: chatIntro ?? this.chatIntro,
        chatPlaceholder: chatPlaceholder ?? this.chatPlaceholder,
        callIntro: callIntro ?? this.callIntro,
        showPoweredBy: showPoweredBy ?? this.showPoweredBy,
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
  final titleRaw = map['chat_title']?.toString().trim() ?? '';
  final placeholderRaw = map['chat_placeholder']?.toString().trim() ?? '';
  return SiteAiAssistantDraft(
    chatEnabled: chatEnabled,
    callEnabled: callEnabled,
    chatTitle: titleRaw,
    chatIntro: map['chat_intro']?.toString() ?? '',
    chatPlaceholder: placeholderRaw,
    callIntro: map['call_intro']?.toString() ?? '',
    showPoweredBy: map['show_powered_by'] != false,
    configured: true,
  );
}

Map<String, dynamic> siteAiAssistantToJson(SiteAiAssistantDraft draft) => {
      'chat_enabled': draft.chatEnabled,
      'call_enabled': draft.callEnabled,
      'floating_bubble': draft.chatEnabled,
      'chat_title': draft.chatTitle,
      'chat_intro': draft.chatIntro,
      'chat_placeholder': draft.chatPlaceholder,
      'call_intro': draft.callIntro,
      'show_powered_by': draft.showPoweredBy,
    };