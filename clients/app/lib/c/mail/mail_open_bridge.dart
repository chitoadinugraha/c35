import 'dart:async';

/// In-app mail open while [PageMail] is mounted (notification tap without re-push).
class MailOpenBridge {
  MailOpenBridge._();
  static final instance = MailOpenBridge._();

  bool Function()? isMailMounted;
  Future<void> Function(int messageId, int mailboxId)? onOpenMessage;

  /// Returns true when [PageMail] handled the open in place.
  bool requestOpen(int messageId, {int mailboxId = 0}) {
    if (messageId <= 0) return false;
    if (isMailMounted?.call() != true) return false;
    final handler = onOpenMessage;
    if (handler == null) return false;
    unawaited(handler(messageId, mailboxId));
    return true;
  }
}
