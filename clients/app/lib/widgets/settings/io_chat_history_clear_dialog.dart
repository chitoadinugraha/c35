import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ui/ui_slide_confirm.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _dangerColor = Color(0xFFEF4444);
const _border = Color(0xFF27272A);
const _bg = Color(0xFF18181B);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);

Future<bool> chatHistoryClearConfirmShow(
  BuildContext context, {
  required ChatConn conn,
  required ChatStore store,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => IoChatHistoryClearDialog(conn: conn, store: store),
  );
  return result == true;
}

enum _ClearPhase { confirm, countdown, ready, clearing }

class IoChatHistoryClearDialog extends StatefulWidget {
  const IoChatHistoryClearDialog({
    super.key,
    required this.conn,
    required this.store,
  });

  final ChatConn conn;
  final ChatStore store;

  @override
  State<IoChatHistoryClearDialog> createState() => _IoChatHistoryClearDialogState();
}

class _IoChatHistoryClearDialogState extends State<IoChatHistoryClearDialog> {
  var _phase = _ClearPhase.confirm;
  var _countdown = 3;
  var _error = '';
  var _loading = true;
  var _msgs = 0;
  var _chats = 0;
  Timer? _countdownTimer;

  bool get _busy => _phase == _ClearPhase.countdown || _phase == _ClearPhase.clearing;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCounts());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    try {
      final res = await widget.conn.chatHistoryClear(dryRun: true);
      if (!mounted) return;
      setState(() {
        _msgs = res.msgsDeleted;
        _chats = res.chatsAffected;
        _loading = false;
      });
    } catch (e, st) {
      lError('chat history count: $e\n$st');
      if (!mounted) return;
      setState(() {
        _msgs = widget.store.msgs.length;
        _chats = widget.store.chats.where((c) => widget.store.msgs.any((m) => m.chatId == c.id)).length;
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _onSlideConfirm() {
    if (_phase != _ClearPhase.confirm || _loading || _msgs <= 0) return;
    setState(() {
      _phase = _ClearPhase.countdown;
      _countdown = 3;
      _error = '';
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _phase = _ClearPhase.ready);
        return;
      }
      setState(() => _countdown--);
    });
  }

  Future<void> _clear() async {
    if (_phase != _ClearPhase.ready) return;
    setState(() {
      _phase = _ClearPhase.clearing;
      _error = '';
    });
    try {
      await widget.store.chatHistoryClearRemote(widget.conn);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      lError('chat history clear: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _ClearPhase.ready;
        _error = '$e';
      });
    }
  }

  String _countLabel() {
    final msgWord = _msgs == 1 ? 'settings.clearChatHistoryMsgOne'.tr() : 'settings.clearChatHistoryMsgMany'.tr(args: ['$_msgs']);
    if (_chats <= 0) return msgWord;
    final chatWord = _chats == 1 ? 'settings.clearChatHistoryChatOne'.tr() : 'settings.clearChatHistoryChatMany'.tr(args: ['$_chats']);
    return 'settings.clearChatHistoryCount'.tr(args: [msgWord, chatWord]);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _border),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'settings.clearChatHistoryTitle'.tr(),
                style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            uiIconButton(
              tooltip: 'Cancel',
              visualDensity: VisualDensity.compact,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close, color: _muted, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'settings.clearChatHistoryWarning'.tr(),
                style: const TextStyle(color: _title, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _dangerColor))),
                )
              else if (_msgs <= 0)
                Text(
                  'settings.clearChatHistoryEmpty'.tr(),
                  style: const TextStyle(color: _muted, fontSize: 13),
                )
              else
                Text(
                  _countLabel(),
                  style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
                ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: _dangerColor, fontSize: 12)),
              ],
              ...switch (_phase) {
                _ClearPhase.confirm when !_loading && _msgs > 0 => [
                    const SizedBox(height: 20),
                    UiSlideConfirm(
                      enabled: true,
                      color: _dangerColor,
                      label: 'settings.clearChatHistorySlide'.tr(),
                      doneLabel: 'settings.clearChatHistorySlideDone'.tr(),
                      onConfirm: _onSlideConfirm,
                    ),
                  ],
                _ClearPhase.countdown => [
                    const SizedBox(height: 24),
                    Text(
                      'settings.clearChatHistoryCountdown'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_countdown',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        color: _dangerColor,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                _ClearPhase.ready => [
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _clear,
                      style: FilledButton.styleFrom(
                        backgroundColor: _dangerColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      child: Text('settings.clearChatHistoryConfirm'.tr()),
                    ),
                  ],
                _ClearPhase.clearing => [
                    const SizedBox(height: 20),
                    const SizedBox(
                      height: 50,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _dangerColor),
                        ),
                      ),
                    ),
                  ],
                _ => const [],
              },
            ],
          ),
        ),
      );
}
