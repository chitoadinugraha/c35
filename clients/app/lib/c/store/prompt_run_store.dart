import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:flutter/foundation.dart';

bool promptRunStatusLive(String status) {
  final s = status.trim().toLowerCase();
  return s == 'queued' || s == 'running' || s == 'waiting_child';
}

String promptRunStatusLabel(String status) {
  final s = status.trim().toLowerCase();
  return switch (s) {
    'queued' => 'Queued',
    'running' => 'Running',
    'waiting_child' => 'Waiting',
    'done' => 'Done',
    'failed' => 'Failed',
    'cancelled' => 'Cancelled',
    _ => status.isNotEmpty ? status : 'Unknown',
  };
}

/// Live map of `req_id -> PromptRunPush` for subagent UI cards.
class PromptRunStore extends ChangeNotifier {
  PromptRunStore._();

  static final PromptRunStore instance = PromptRunStore._();

  final _runs = <String, PromptRunPush>{};

  PromptRunPush? get(String reqId) => _runs[reqId.trim()];

  List<PromptRunPush> childrenFor(String parentReqId) {
    final parent = parentReqId.trim();
    if (parent.isEmpty) return const [];
    return [for (final run in _runs.values) if (run.parentReqId == parent) run];
  }

  void put(PromptRunPush push) {
    final id = push.reqId.trim();
    if (id.isEmpty) return;
    _runs[id] = push;
    notifyListeners();
  }

  void clearForParent(String parentReqId) {
    final parent = parentReqId.trim();
    if (parent.isEmpty) return;
    _runs.removeWhere((_, run) => run.parentReqId == parent);
    notifyListeners();
  }

  void clear() {
    if (_runs.isEmpty) return;
    _runs.clear();
    notifyListeners();
  }
}
