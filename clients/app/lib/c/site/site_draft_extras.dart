import 'dart:convert';

/// Draft extras stored on `SiteDoc.metaJson` (the `meta` object inside `site.draft.doc_json`).
/// `draftPut` round-trips `meta`, so these keys survive the existing Info save path.

const kSiteOrderRingOnce = 'once';
const kSiteOrderRingUntilHandled = 'until_handled';

class SiteKnowledgeDraft {
  const SiteKnowledgeDraft({required this.id, this.title = '', this.content = ''});

  final String id;
  final String title;
  final String content;

  SiteKnowledgeDraft copyWith({String? id, String? title, String? content}) => SiteKnowledgeDraft(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'content': content};
}

class SitePaymentAccountDraft {
  const SitePaymentAccountDraft({
    required this.id,
    this.bank = '',
    this.accountName = '',
    this.accountNumber = '',
    this.qrisPic = '',
  });

  final String id;
  final String bank;
  final String accountName;
  final String accountNumber;
  final String qrisPic;

  SitePaymentAccountDraft copyWith({
    String? id,
    String? bank,
    String? accountName,
    String? accountNumber,
    String? qrisPic,
  }) =>
      SitePaymentAccountDraft(
        id: id ?? this.id,
        bank: bank ?? this.bank,
        accountName: accountName ?? this.accountName,
        accountNumber: accountNumber ?? this.accountNumber,
        qrisPic: qrisPic ?? this.qrisPic,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank': bank,
        'account_name': accountName,
        'account_number': accountNumber,
        'qris_pic': qrisPic,
      };
}

class SiteDraftExtras {
  const SiteDraftExtras({
    this.knowledge = const [],
    this.orderRing = kSiteOrderRingUntilHandled,
    this.paymentAccounts = const [],
  });

  final List<SiteKnowledgeDraft> knowledge;
  final String orderRing;
  final List<SitePaymentAccountDraft> paymentAccounts;
}

Map<String, dynamic> siteDraftJsonMap(String raw) {
  if (raw.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
  } catch (_) {}
  return {};
}

Map<String, dynamic> _asStringMap(Object? raw) {
  if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
  return {};
}

String siteOrderRingNormalize(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  if (v == kSiteOrderRingOnce) return kSiteOrderRingOnce;
  return kSiteOrderRingUntilHandled;
}

String siteOrderRingRead(Map<String, dynamic> map) {
  final notify = map['notify'];
  if (notify is! Map) return kSiteOrderRingUntilHandled;
  final ring = _asStringMap(notify)['order_ring'];
  if (ring == null) return kSiteOrderRingUntilHandled;
  return siteOrderRingNormalize(ring.toString());
}

SiteKnowledgeDraft? siteKnowledgeFromJson(Object? raw) {
  final m = _asStringMap(raw);
  if (m.isEmpty) return null;
  final id = m['id']?.toString() ?? '';
  if (id.isEmpty) return null;
  return SiteKnowledgeDraft(
    id: id,
    title: m['title']?.toString() ?? '',
    content: m['content']?.toString() ?? '',
  );
}

SitePaymentAccountDraft? sitePaymentAccountFromJson(Object? raw) {
  final m = _asStringMap(raw);
  if (m.isEmpty) return null;
  final id = m['id']?.toString() ?? '';
  if (id.isEmpty) return null;
  return SitePaymentAccountDraft(
    id: id,
    bank: m['bank']?.toString() ?? '',
    accountName: m['account_name']?.toString() ?? '',
    accountNumber: m['account_number']?.toString() ?? '',
    qrisPic: m['qris_pic']?.toString() ?? '',
  );
}

List<SiteKnowledgeDraft> siteKnowledgeListRead(Object? raw) {
  if (raw is! List) return const [];
  return [for (final item in raw) siteKnowledgeFromJson(item)].whereType<SiteKnowledgeDraft>().toList(growable: false);
}

List<SitePaymentAccountDraft> sitePaymentAccountListRead(Object? raw) {
  if (raw is! List) return const [];
  return [for (final item in raw) sitePaymentAccountFromJson(item)].whereType<SitePaymentAccountDraft>().toList(growable: false);
}

SiteDraftExtras siteDraftExtrasParse(String metaJson) {
  final map = siteDraftJsonMap(metaJson);
  return SiteDraftExtras(
    knowledge: siteKnowledgeListRead(map['knowledge']),
    orderRing: siteOrderRingRead(map),
    paymentAccounts: sitePaymentAccountListRead(map['payment_accounts']),
  );
}

String siteDraftExtrasMerge(
  String metaJson, {
  List<SiteKnowledgeDraft>? knowledge,
  String? orderRing,
  List<SitePaymentAccountDraft>? paymentAccounts,
}) {
  final map = siteDraftJsonMap(metaJson);
  if (knowledge != null) {
    map['knowledge'] = knowledge.map((e) => e.toJson()).toList(growable: false);
  }
  if (orderRing != null) {
    final notify = _asStringMap(map['notify']);
    notify['order_ring'] = siteOrderRingNormalize(orderRing);
    map['notify'] = notify;
  }
  if (paymentAccounts != null) {
    map['payment_accounts'] = paymentAccounts.map((e) => e.toJson()).toList(growable: false);
  }
  return jsonEncode(map);
}

String siteDraftNewId(String prefix) {
  final n = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '$prefix$n';
}
