import 'dart:convert';

enum MailDirection { inbound, outbound }

enum MailStatus { unknown, received, queued, sent, failed }

enum MailMailboxKind { personal, site, unspecified }

enum MailMailboxAccess { read, write, unspecified }

class MailAccount {
  const MailAccount({
    required this.uid,
    required this.address,
    required this.createdAt,
    this.mailboxId = 0,
  });

  final int uid;
  final String address;
  final int createdAt;
  final int mailboxId;
}

class MailMailboxMember {
  const MailMailboxMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.access,
  });

  final int uid;
  final String name;
  final String email;
  final MailMailboxAccess access;
}

class MailMailbox {
  const MailMailbox({
    required this.mailboxId,
    required this.address,
    required this.kind,
    required this.siteId,
    required this.siteName,
    required this.label,
    required this.subscriberLimit,
    required this.myAccess,
    required this.unreadCount,
    this.members = const [],
  });

  final int mailboxId;
  final String address;
  final MailMailboxKind kind;
  final int siteId;
  final String siteName;
  final String label;
  final int subscriberLimit;
  final MailMailboxAccess myAccess;
  final int unreadCount;
  final List<MailMailboxMember> members;

  bool get canWrite => myAccess == MailMailboxAccess.write;

  String get displayLabel {
    final l = label.trim();
    if (l.isNotEmpty) return l;
    if (siteName.trim().isNotEmpty) return siteName.trim();
    return address;
  }
}

class MailDomainSetupStep {
  const MailDomainSetupStep({
    required this.key,
    required this.status,
    required this.detail,
  });

  final String key;
  final String status;
  final String detail;

  bool get isOk => status == 'ok';
}

class MailDomain {
  const MailDomain({
    required this.domain,
    required this.zoneId,
    required this.sendingEnabled,
    required this.routingEnabled,
    required this.createdAt,
    this.setupSteps = const [],
    this.errorSummary = '',
  });

  final String domain;
  final String zoneId;
  final bool sendingEnabled;
  final bool routingEnabled;
  final int createdAt;
  final List<MailDomainSetupStep> setupSteps;
  final String errorSummary;

  bool get hasSetupError => errorSummary.trim().isNotEmpty;
}

class MailAttachment {
  const MailAttachment({
    required this.path,
    this.name = '',
    this.mime = '',
    this.size = 0,
  });

  final String path;
  final String name;
  final String mime;
  final int size;

  bool get isImage {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return true;
    final n = name.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp') ||
        n.endsWith('.bmp');
  }

  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty) return n;
    final p = path.trim();
    if (p.isEmpty) return 'attachment';
    final slash = p.lastIndexOf('/');
    return slash >= 0 ? p.substring(slash + 1) : p;
  }

  static MailAttachment? fromJson(dynamic raw) {
    if (raw is String) {
      final path = raw.trim();
      if (!path.startsWith('/fs/')) return null;
      return MailAttachment(path: path);
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final path = '${map['path'] ?? map['url'] ?? ''}'.trim();
    if (!path.startsWith('/fs/')) return null;
    return MailAttachment(
      path: path,
      name: '${map['name'] ?? map['label'] ?? ''}'.trim(),
      mime: '${map['mime'] ?? ''}'.trim(),
      size: (map['size'] as num?)?.toInt() ?? int.tryParse('${map['size'] ?? ''}') ?? 0,
    );
  }

  static List<MailAttachment> parseList(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '[]') return const [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return const [];
      return decoded.map(fromJson).whereType<MailAttachment>().toList();
    } catch (_) {
      return const [];
    }
  }
}

enum MailBodyRenderKind {
  empty,
  plainText,
  markdown,
  html,
}

class MailMessage {
  const MailMessage({
    required this.messageId,
    required this.direction,
    required this.fromAddr,
    required this.toAddr,
    required this.subject,
    required this.bodyText,
    required this.bodyHtml,
    required this.status,
    required this.error,
    required this.createdAt,
    required this.sentAt,
    this.isArchived = false,
    this.isRead = false,
    this.attachments = const [],
  });

  final int messageId;
  final MailDirection direction;
  final String fromAddr;
  final String toAddr;
  final String subject;
  final String bodyText;
  final String bodyHtml;
  final MailStatus status;
  final String error;
  final int createdAt;
  final int sentAt;
  final bool isArchived;
  final bool isRead;
  final List<MailAttachment> attachments;

  String get preview {
    final raw = bodyText.trim().isNotEmpty ? bodyText : bodyHtml;
    final plain = mailBodyPlain(raw);
    if (plain.length <= 120) return plain;
    return '${plain.substring(0, 120)}ΓÇª';
  }

  /// Chooses how to render the message body in the thread view.
  MailBodyRenderKind get bodyRenderKind {
    final text = bodyText.trim();
    final html = bodyHtml.trim();

    if (text.isEmpty && html.isEmpty) return MailBodyRenderKind.empty;

    final textLooksHtml = text.isNotEmpty && mailLooksLikeHtml(text);

    // Multipart alternative: plain text wins when present.
    if (text.isNotEmpty && !textLooksHtml) {
      return _plainOrMarkdown(text);
    }

    if (html.isNotEmpty) {
      final htmlPlain = mailBodyPlain(html);
      if (htmlPlain.isEmpty && !mailLooksLikeComplexHtml(html)) {
        return MailBodyRenderKind.empty;
      }
      return MailBodyRenderKind.html;
    }

    if (textLooksHtml) {
      if (mailBodyPlain(text).isEmpty) return MailBodyRenderKind.empty;
      return MailBodyRenderKind.plainText;
    }

    return MailBodyRenderKind.empty;
  }

  String get displayHtml {
    final html = bodyHtml.trim();
    if (html.isNotEmpty) return html;
    return bodyText.trim();
  }

  MailBodyRenderKind _plainOrMarkdown(String text) {
    if (mailLooksLikeMarkdown(text)) return MailBodyRenderKind.markdown;
    return MailBodyRenderKind.plainText;
  }

  static String mailBodyPlain(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (!mailLooksLikeHtml(trimmed)) {
      return trimmed.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return trimmed
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool mailLooksLikeHtml(String raw) =>
      RegExp(r'<[a-z!/]', caseSensitive: false).hasMatch(raw.trim());

  static bool mailLooksLikeComplexHtml(String html) => RegExp(
        r'<(table|img|a\s|style=|class=|blockquote|ul|ol|h[1-6]|span|font)',
        caseSensitive: false,
      ).hasMatch(html);

  static bool mailLooksLikeMarkdown(String text) => RegExp(
        r'^#{1,6}\s|^\s*[-*+]\s|\*\*|__|^\s*\d+\.\s|```',
        multiLine: true,
      ).hasMatch(text);
}

class MailingListGroup {
  const MailingListGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.emails,
  });

  final String id;
  final String name;
  final String description;
  final List<String> emails;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emails': emails,
      };

  factory MailingListGroup.fromJson(Map<String, dynamic> json) => MailingListGroup(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        emails: (json['emails'] as List? ?? []).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList(),
      );
}

class MailBroadcastFailure {
  const MailBroadcastFailure({required this.toAddr, required this.error});

  final String toAddr;
  final String error;
}

class MailBroadcastResult {
  const MailBroadcastResult({required this.sentCount, required this.failures});

  final int sentCount;
  final List<MailBroadcastFailure> failures;
}
