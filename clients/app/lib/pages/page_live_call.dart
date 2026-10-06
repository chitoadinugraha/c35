import 'dart:async';
import 'dart:math' as math;

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/live/live_call_session.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/settings/live_call_prefs.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_live_offer_icon.dart';
import 'package:alienai_c35/widgets/ai/ui_mention_chip.dart';
import 'package:flutter/material.dart';

class PageLiveCall extends StatefulWidget {
  const PageLiveCall({
    super.key,
    required this.conn,
    required this.offer,
    this.chatId,
    this.chatStore,
    this.mentionIds = const [],
    this.mentionLabel = '',
    this.onMentions,
  });

  final ChatConn conn;
  final LiveOffer offer;
  final int? chatId;
  final ChatStore? chatStore;
  final List<String> mentionIds;
  final String mentionLabel;
  final void Function(List<String> mentionIds)? onMentions;

  @override
  State<PageLiveCall> createState() => _PageLiveCallState();
}

class _PageLiveCallState extends State<PageLiveCall> {
  late final LiveCallSession _session = LiveCallSession();
  var _busy = false;
  String? _error;
  DateTime? _connectedAt;
  Timer? _callDurationTimer;
  int _callElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _session.ready.addListener(_onSessionReadyChanged);
    _session.error.addListener(_onSessionError);
    _session.onTurnCommitted = _onTurnCommitted;
    if (widget.mentionLabel.trim().isNotEmpty) _session.mentionLabel.value = widget.mentionLabel;
  }

  void _onTurnCommitted(Map<String, dynamic> committed) {
    final cid = (committed['chat_id'] as num?)?.toInt() ?? widget.chatId;
    final uId = (committed['user_msg_id'] as num?)?.toInt();
    final uText = committed['user_text']?.toString() ?? '';
    final aId = (committed['assistant_msg_id'] as num?)?.toInt();
    final aText = committed['assistant_text']?.toString() ?? '';
    if (cid != null && cid > 0 && widget.chatStore != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (uText.isNotEmpty) {
        widget.chatStore!.msgPut(MsgRow(
          id: uId ?? widget.chatStore!.msgNextLocalId(),
          chatId: cid,
          role: 'user',
          content: uText,
          createdAtMs: now,
        ));
      }
      if (aText.isNotEmpty) {
        widget.chatStore!.msgPut(MsgRow(
          id: aId ?? widget.chatStore!.msgNextLocalId(),
          chatId: cid,
          role: 'assistant',
          content: aText,
          createdAtMs: now + 1,
        ));
      }
    }
  }

  void _onSessionReadyChanged() {
    if (_session.ready.value) {
      _connectedAt = DateTime.now();
      _callElapsedSeconds = 0;
      _callDurationTimer?.cancel();
      _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_session.ready.value) return;
        setState(() {
          _callElapsedSeconds = _connectedAt != null ? DateTime.now().difference(_connectedAt!).inSeconds : 0;
        });
      });
      if (mounted) setState(() {});
    } else {
      _callDurationTimer?.cancel();
      _callDurationTimer = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _session.ready.removeListener(_onSessionReadyChanged);
    _session.error.removeListener(_onSessionError);
    _session.dispose();
    super.dispose();
  }

  static String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.conn.liveStart(
        offerId: widget.offer.id,
        chatId: widget.chatId,
        mentionIds: widget.mentionIds,
      );
      if (res.error.isNotEmpty) {
        setState(() => _error = res.error);
      } else {
        await LiveCallPrefs.setLastOfferId(widget.offer.id);
        await _session.connect(res);
        if (_session.error.value != null) setState(() => _error = _session.error.value);
      }
    } catch (e) {
      setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSessionError() {
    if (!mounted) return;
    setState(() => _error = _session.error.value);
  }

  Future<void> _hangup() async {
    await _session.hangup();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([AppStore.instance, _session.connected, _session.ready, _session.mentionLabel, _session.switching]),
      builder: (context, _) {
          final wallet = AppStore.instance.wallet;
          final frontier5hRem = (wallet.frontierAllow5hLimit - wallet.frontierAllow5hUsed).clamp(0.0, double.infinity);
          final frontierWeeklyRem = (wallet.frontierAllowWeeklyLimit - wallet.frontierAllowWeeklyUsed).clamp(0.0, double.infinity);
          final allowanceRem = (wallet.frontierAllow5hLimit > 0 && wallet.frontierAllowWeeklyLimit > 0)
              ? math.min(frontier5hRem, frontierWeeklyRem)
              : (wallet.frontierAllow5hLimit > 0
                  ? frontier5hRem
                  : (wallet.frontierAllowWeeklyLimit > 0 ? frontierWeeklyRem : 0.0));

          final pricePerSec = liveOfferPricePerSecLocal(
            widget.offer,
            currency: wallet.billingCurrency,
            fxMicroPerUsd: wallet.fxMicroPerUsd,
          );

          final retailUsdPerMin = widget.offer.retailUsdPerMin;

          final double includedMinutes;
          final double quotaRemainingRatio;
          final bool showQuotaBar;

          double frontierRemainRatio(double rem, double limit) => limit > 0 ? (rem / limit).clamp(0.0, 1.0) : 0.0;
          final ratio5h = frontierRemainRatio(frontier5hRem, wallet.frontierAllow5hLimit);
          final ratio7d = frontierRemainRatio(frontierWeeklyRem, wallet.frontierAllowWeeklyLimit);
          final hasFrontierRings = wallet.frontierAllow5hLimit > 0 || wallet.frontierAllowWeeklyLimit > 0;

          if (hasFrontierRings && retailUsdPerMin > 0) {
            includedMinutes = allowanceRem / retailUsdPerMin;
            quotaRemainingRatio = wallet.frontierAllow5hLimit > 0 && wallet.frontierAllowWeeklyLimit > 0
                ? math.min(ratio5h, ratio7d)
                : (wallet.frontierAllow5hLimit > 0 ? ratio5h : ratio7d);
            showQuotaBar = true;
          } else {
            includedMinutes = 0.0;
            quotaRemainingRatio = 0.0;
            showQuotaBar = false;
          }

          final on = _session.connected.value;
          final ready = _session.ready.value;
          final status = on
              ? (ready ? 'Connected — speak naturally' : 'Connecting to voice…')
              : (!widget.offer.enabled ? liveOfferSoonTag() : '');

          return Scaffold(
            backgroundColor: const Color(0xFF09090B),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.35),
                  radius: 1.1,
                  colors: [Color(0xFF1A1A1F), Color(0xFF09090B)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFA1A1AA)),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _avatarRing(on: on, ready: ready),
                                  const SizedBox(height: 18),
                                  Text(
                                    liveOfferLabel(widget.offer),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFAFAFA),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (_session.mentionLabel.value.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    UiMentionChip(
                                      label: _session.mentionLabel.value,
                                      onClear: () {
                                        _session.clearMention();
                                        widget.onMentions?.call(const []);
                                      },
                                    ),
                                  ],
                                  if (_session.switching.value)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Switching mention…', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                                    ),
                                  if (on && ready) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDuration(_callElapsedSeconds),
                                      style: const TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Builder(
                                      builder: (_) {
                                        final accruedUsd = (widget.offer.retailUsdPerMin / 60.0) * _callElapsedSeconds;
                                        final accruedLabel = moneyCostLabel(
                                          accruedUsd,
                                          currency: wallet.billingCurrency,
                                          fxMicroPerUsd: wallet.fxMicroPerUsd,
                                        );
                                        final caption = accruedLabel.isNotEmpty
                                            ? '$accruedLabel · billed per second'
                                            : 'Billed per second';
                                        return Text(
                                          caption,
                                          style: const TextStyle(
                                            color: Color(0xFFA1A1AA),
                                            fontSize: 12,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  if (pricePerSec.isNotEmpty && (!on || !ready)) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF18181B),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFF27272A)),
                                      ),
                                      child: Text(
                                        pricePerSec,
                                        style: const TextStyle(
                                          color: Color(0xFFD4D4D8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                    if (showQuotaBar) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 260,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF121215),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFF27272A)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF60A5FA)),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Frontier quota',
                                                  style: TextStyle(
                                                    color: Color(0xFFA1A1AA),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatIncludedMinutes(includedMinutes),
                                                  style: TextStyle(
                                                    color: includedMinutes > 0 ? const Color(0xFF60A5FA) : const Color(0xFFEF4444),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    fontFeatures: const [FontFeature.tabularFigures()],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: quotaRemainingRatio,
                                                minHeight: 4,
                                                backgroundColor: const Color(0xFF60A5FA).withValues(alpha: 0.15),
                                                valueColor: const AlwaysStoppedAnimation(Color(0xFF60A5FA)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                  if (status.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                                  ],
                                  ValueListenableBuilder<LiveCaption?>(
                                    valueListenable: _session.caption,
                                    builder: (_, cap, __) {
                                      if (cap == null || cap.text.trim().isEmpty || !on || !ready) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(top: 14),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 130),
                                        decoration: BoxDecoration(
                                          color: cap.isUser
                                              ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                                              : const Color(0xFF141416).withValues(alpha: 0.92),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: cap.isUser
                                                ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                                : const Color(0xFF27272A),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: SingleChildScrollView(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Icon(
                                                  cap.isUser ? Icons.mic_rounded : Icons.auto_awesome_rounded,
                                                  size: 15,
                                                  color: cap.isUser ? const Color(0xFF38BDF8) : const Color(0xFF22C55E),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  cap.text.trim(),
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                    color: cap.isUser ? const Color(0xFFE2E8F0) : const Color(0xFFF4F4F5),
                                                    fontSize: 13.5,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (PromptUsagePrefs.instance.showUsageStats)
                                    ValueListenableBuilder<LiveUsage?>(
                                      valueListenable: _session.usage,
                                      builder: (_, u, __) => u == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Text(
                                                '${u.totalTokens} tokens · in ${u.promptTokens} · out ${u.responseTokens}',
                                                style: const TextStyle(color: Color(0xFF52525B), fontSize: 11),
                                              ),
                                            ),
                                    ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 14),
                                    _errorBanner(_error!),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _callButton(on: on),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  static String _formatIncludedMinutes(double totalMins) {
    if (totalMins <= 0) return 'Exhausted';
    if (totalMins < 1.0) {
      final secs = (totalMins * 60).round();
      return '${secs}s included';
    }
    final totalRoundMins = totalMins.round();
    final hours = totalRoundMins ~/ 60;
    final mins = totalRoundMins % 60;
    if (hours > 0) {
      if (mins > 0) {
        return '${hours}h ${mins}m included';
      } else {
        return '${hours}h included';
      }
    }
    return '${mins}m included';
  }

  Widget _avatarRing({required bool on, required bool ready}) {
    final ring = on
        ? (ready ? const Color(0xFF22C55E) : const Color(0xFFEAB308))
        : const Color(0xFF3F3F46);
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 3),
        boxShadow: [
          BoxShadow(color: ring.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF18181B),
        ),
        child: Center(child: UiLiveOfferIcon(offer: widget.offer, size: 48)),
      ),
    );
  }

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF450A0A).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7F1D1D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFF87171)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13, height: 1.35)),
            ),
          ],
        ),
      );

  Widget _callButton({required bool on}) {
    if (on) {
      return _roundCallButton(
        color: const Color(0xFFDC2626),
        icon: Icons.call_end_rounded,
        size: 76,
        onTap: _hangup,
      );
    }
    if (_busy) {
      return const SizedBox(
        width: 76,
        height: 76,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFAFAFA))),
      );
    }
    return _roundCallButton(
      color: widget.offer.enabled ? const Color(0xFF16A34A) : const Color(0xFF3F3F46),
      icon: Icons.phone_rounded,
      size: 76,
      onTap: widget.offer.enabled ? _connect : null,
    );
  }

  Widget _roundCallButton({
    required Color color,
    required IconData icon,
    required double size,
    VoidCallback? onTap,
  }) =>
      Material(
        color: color,
        elevation: onTap != null ? 6 : 0,
        shadowColor: color.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: 34)),
        ),
      );
}
