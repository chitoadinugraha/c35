import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:flutter/foundation.dart';

class PromptFollowupStore extends ChangeNotifier {
  PromptFollowupStore._();
  static final PromptFollowupStore instance = PromptFollowupStore._();

  final List<PromptFollowupRow> items = [];
  String activeReqId = '';

  void merge(ResPromptFollowupList res) {
    activeReqId = res.activeReqId;
    items
      ..clear()
      ..addAll(res.items);
    notifyListeners();
  }

  void mergePush(PromptFollowupPush push) {
    activeReqId = push.activeReqId;
    items
      ..clear()
      ..addAll(push.items);
    notifyListeners();
  }

  void clear() {
    items.clear();
    activeReqId = '';
    notifyListeners();
  }
}
