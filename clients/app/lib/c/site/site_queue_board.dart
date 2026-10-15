import 'package:alienai_c35/c/pb/c35/site.pb.dart';

/// Staff queue board view models.
class SiteQueueBoardTicket {
  const SiteQueueBoardTicket({
    required this.ticketId,
    required this.ticketNo,
    required this.displayLabel,
    required this.status,
    this.guestName = '',
    this.guestPhone = '',
  });

  final int ticketId;
  final int ticketNo;
  final String displayLabel;
  final String status;
  final String guestName;
  final String guestPhone;

  static SiteQueueBoardTicket fromJson(Map<String, dynamic> j) => SiteQueueBoardTicket(
        ticketId: (j['ticket_id'] as num?)?.toInt() ?? 0,
        ticketNo: (j['ticket_no'] as num?)?.toInt() ?? 0,
        displayLabel: (j['display_label'] as String?)?.trim() ?? '',
        status: (j['status'] as String?)?.trim() ?? 'waiting',
        guestName: (j['guest_name'] as String?)?.trim() ?? '',
        guestPhone: (j['guest_phone'] as String?)?.trim() ?? '',
      );

  static SiteQueueBoardTicket fromProto(SiteQueueTicket t) => SiteQueueBoardTicket(
        ticketId: t.ticketId.toInt(),
        ticketNo: t.ticketNo,
        displayLabel: t.displayLabel.trim(),
        status: t.status.trim().isEmpty ? 'waiting' : t.status.trim(),
        guestName: t.guestName.trim(),
        guestPhone: t.guestPhone.trim(),
      );
}

class SiteQueueBoardSnapshot {
  const SiteQueueBoardSnapshot({
    required this.queueId,
    required this.servingTicketNo,
    required this.servingLabel,
    required this.waiting,
    required this.called,
    this.lastTicketNo = 0,
  });

  final int queueId;
  final int servingTicketNo;
  final String servingLabel;
  final int lastTicketNo;
  final List<SiteQueueBoardTicket> waiting;
  final List<SiteQueueBoardTicket> called;

  static SiteQueueBoardSnapshot fromJson(Map<String, dynamic> j) {
    final waiting = <SiteQueueBoardTicket>[];
    final called = <SiteQueueBoardTicket>[];
    void addList(String key, List<SiteQueueBoardTicket> out) {
      final raw = j[key];
      if (raw is! List) return;
      for (final item in raw) {
        if (item is Map) out.add(SiteQueueBoardTicket.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    addList('waiting', waiting);
    addList('called', called);
    return SiteQueueBoardSnapshot(
      queueId: (j['queue_id'] as num?)?.toInt() ?? 0,
      servingTicketNo: (j['serving_ticket_no'] as num?)?.toInt() ?? 0,
      servingLabel: (j['serving_label'] as String?)?.trim() ?? '',
      lastTicketNo: (j['last_ticket_no'] as num?)?.toInt() ?? 0,
      waiting: waiting,
      called: called,
    );
  }

  static SiteQueueBoardSnapshot fromProto(SiteQueueBoard board, {required int queueId}) {
    final q = board.hasQueue() ? board.queue : null;
    final run = board.hasRun() ? board.run : null;
    final resolvedQueueId = q != null && q.hasQueueId() ? q.queueId.toInt() : queueId;
    var servingNo = run != null ? run.servingNumber : 0;
    var servingLabel = '';
    if (board.hasServing()) {
      final s = board.serving;
      servingLabel = s.displayLabel.trim();
      if (servingNo == 0) servingNo = s.ticketNo;
    } else if (board.hasCalled()) {
      final c = board.called;
      servingLabel = c.displayLabel.trim();
      if (servingNo == 0) servingNo = c.ticketNo;
    }
    final waiting = board.waiting.map(SiteQueueBoardTicket.fromProto).toList(growable: false);
    final called = <SiteQueueBoardTicket>[];
    if (board.hasCalled()) {
      called.add(SiteQueueBoardTicket.fromProto(board.called));
    }
    final lastNo = q != null ? q.lastTicketNo : 0;
    return SiteQueueBoardSnapshot(
      queueId: resolvedQueueId,
      servingTicketNo: servingNo,
      servingLabel: servingLabel,
      lastTicketNo: lastNo,
      waiting: waiting,
      called: called,
    );
  }
}
