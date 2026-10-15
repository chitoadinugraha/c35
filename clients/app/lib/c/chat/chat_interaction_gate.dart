/// Coalesce heavy main-thread work while the user is typing in Home composer.
class ChatInteractionGate {
  static const _typingHold = Duration(milliseconds: 1600);

  static DateTime _typingUntil = DateTime.fromMillisecondsSinceEpoch(0);

  static void markComposerActive() {
    _typingUntil = DateTime.now().add(_typingHold);
  }

  static bool get composerTypingActive => DateTime.now().isBefore(_typingUntil);
}
