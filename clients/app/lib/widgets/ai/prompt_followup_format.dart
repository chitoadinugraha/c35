import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
String promptFollowupRejectLabel(String reason, {String? localeCode}) {
  final code = localeCode ?? 'en';
  final id = code.startsWith('id');
  switch (reason) {
    case 'plan_cap':
      return id
          ? 'Antrian pesan saat AI sibuk tidak tersedia di paket Lite. Naikkan paket atau tunggu jawaban selesai.'
          : 'Message queue while the AI is busy is not on your Lite plan. Upgrade or wait for the reply to finish.';
    case 'queue_full':
      return id ? 'Antrian penuh. Hapus satu pesan atau tunggu giliran.' : 'Queue is full. Remove a message or wait your turn.';
    case 'steer_cap':
      return id
          ? 'Batas koreksi saat AI berjalan tercapai untuk giliran ini.'
          : 'Steer limit reached for this turn.';
    case 'empty_text':
      return id ? 'Pesan kosong.' : 'Message is empty.';
    case 'disabled':
      return id ? 'Fitur antrian tidak aktif.' : 'Follow-up queue is disabled.';
    case 'duplicate':
      return id ? 'Pesan ini sudah dalam antrian.' : 'This message is already queued.';
    case 'no_active_run':
      return id ? 'Tidak ada jawaban yang sedang berjalan.' : 'No reply in progress.';
    default:
      if (reason.isNotEmpty) return reason;
      return id ? 'Tidak bisa mengantre pesan.' : 'Could not queue message.';
  }
}

List<PromptFollowupRow> promptFollowupQueueRows(List<PromptFollowupRow> items) =>
    items.where((r) => r.kind == PromptFollowupKind.PROMPT_FOLLOWUP_KIND_QUEUE).toList(growable: false);
