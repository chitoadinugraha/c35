import 'dart:async';
import 'dart:math' as math;

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/live/live_call_session.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/settings/live_call_prefs.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_live_offer_icon.dart';
import 'package:alienai_c35/widgets/ai/ui_mention_chip.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_plan_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';

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
      final perm = await sttMicPermissionEnsure();
      if (!perm) {
        setState(() => _error = sttMicErrorMessage());
        return;
      }

      final res = await widget.conn.liveStart(
        offerId: widget.offer.id,
        chatId: widget.chatId,
        mentionIds: widget.mentionIds,
      );
      if (res.error.isNotEmpty) {
        setState(() => _error = uiFriendlyError(res.error));
      } else {
        await LiveCallPrefs.setLastOfferId(widget.offer.id);
        await _session.connect(res);
        if (_session.error.value != null) setState(() => _error = uiFriendlyError(_session.error.value!));
      }
    } catch (e) {
      setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSessionError() {
    if (!mounted) return;
    setState(() => _error = _session.error.value != null ? uiFriendlyError(_session.error.value!) : null);
  }

  Future<void> _hangup() async {
    await _session.hangup();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([
          AppStore.instance,
          _session.connected,
          _session.ready,
          _session.mentionLabel,
          _session.switching,
          _session.cameraActive,
        ]),
      builder: (context, _) {
          final wallet = AppStore.instance.wallet;
          final frontier5hRem = (wallet.frontierAllow5hLimit - wallet.frontierAllow5hUsed).clamp(0.0, double.infinity);
          final frontierWeeklyRem = (wallet.frontierAllowWeeklyLimit - wallet.frontierAllowWeeklyUsed).clamp(0.0, double.infinity);
          final allowanceRem = (wallet.frontierAllow5hLimit > 0 && wallet.frontierAllowWeeklyLimit > 0)
              ? math.min(frontier5hRem, frontierWeeklyRem)
              : (wallet.frontierAllow5hLimit > 0
                  ? frontier5hRem
                  : (wallet.frontierAllowWeeklyLimit > 0 ? frontierWeeklyRem : 0.0));

          final pricePerSec = liveOfferPricePerSecDualLocal(
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
              ? (ready ? '' : 'Connecting to voice…')
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
                                  _stageVisual(on: on, ready: ready),
                                  const SizedBox(height: 18),
                                  Text(
                                    liveOfferActionTitle(widget.offer),
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
                                  ValueListenableBuilder<String?>(
                                    valueListenable: _session.activeAttachmentName,
                                    builder: (context, attachmentName, _) {
                                      if (attachmentName == null || attachmentName.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF27272A),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFF3F3F46)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF38BDF8)),
                                              const SizedBox(width: 4),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 180),
                                                child: Text(
                                                  attachmentName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: _session.clearMediaAttachment,
                                                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFA1A1AA)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
                                    ListenableBuilder(
                                      listenable: _session.cameraActive,
                                      builder: (_, __) {
                                        final isVideo = _session.cameraActive.value;
                                        final ratePerMin = isVideo && widget.offer.retailVideoUsdPerMin > 0
                                            ? widget.offer.retailVideoUsdPerMin
                                            : widget.offer.retailUsdPerMin;
                                        final accruedUsd = (ratePerMin / 60.0) * _callElapsedSeconds;
                                        final accruedLabel = moneyCostLabel(
                                          accruedUsd,
                                          currency: wallet.billingCurrency,
                                          fxMicroPerUsd: wallet.fxMicroPerUsd,
                                        );
                                        if (accruedLabel.isEmpty) return const SizedBox.shrink();
                                        return Text(
                                          accruedLabel,
                                          style: const TextStyle(
                                            color: Color(0xFFA1A1AA),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
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
                                  _transcriptBubbles(on: on, ready: ready),
                                  _toolExecutingIndicator(on: on, ready: ready),
                                  if (PromptUsagePrefs.instance.showUsageStats)
                                    ValueListenableBuilder<LiveUsage?>(
                                      valueListenable: _session.usage,
                                      builder: (_, u, __) => u == null
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Text(
                                                '${uiFmtGroupedInt(u.totalTokens)} tokens · in ${uiFmtGroupedInt(u.promptTokens)} · out ${uiFmtGroupedInt(u.responseTokens)}',
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
                      _callControls(on: on),
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

  Widget _stageVisual({required bool on, required bool ready}) {
    return ListenableBuilder(
      listenable: _session.cameraActive,
      builder: (context, _) {
        if (on && _session.cameraActive.value && _session.cameraRenderer != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 280,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RTCVideoView(
                      _session.cameraRenderer!,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _session.switchCamera,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _avatarRing(on: on, ready: ready);
      },
    );
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

  Widget _transcriptBubbles({required bool on, required bool ready}) {
    if (!on || !ready) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([_session.userTranscript, _session.responseTranscript]),
      builder: (context, _) {
        final userText = _session.userTranscript.value?.trim();
        final resText = _session.responseTranscript.value?.trim();

        if ((userText == null || userText.isEmpty) && (resText == null || resText.isEmpty)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 14),
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User speech bubble (Right)
              if (userText != null && userText.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            userText,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.mic_rounded, size: 14, color: Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                  ),
                ),

              // AI response bubble (Left)
              if (resText != null && resText.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416).withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: const Color(0xFF27272A)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF22C55E)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            resText,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F5),
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolExecutingIndicator({required bool on, required bool ready}) {
    if (!on || !ready) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: _session.activeToolName,
      builder: (_, toolName, __) {
        if (toolName == null || toolName.isEmpty) return const SizedBox.shrink();
        final label = _formatToolStatus(toolName);
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatToolStatus(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('consumption') || lower.contains('food') || lower.contains('makan')) {
      return _tr('tool.consumption.calling', 'Memeriksa makanan hari ini…');
    }
    if (lower.contains('search') || lower.contains('web')) {
      return _tr('tool.search.calling', 'Mencari informasi terkini…');
    }
    if (lower.contains('weather') || lower.contains('cuaca')) {
      return _tr('tool.weather.calling', 'Memeriksa perkiraan cuaca…');
    }
    return _tr('tool.executing', 'Menjalankan alat: $name…');
  }

  Widget _errorBanner(String message) {
    final quota = uiIsQuotaError(message);
    final displayMsg = quota && message == uiCannotConnectToAlienAi
        ? 'Out of call quota. Upgrade your plan to continue.'
        : message;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: quota
            ? const Color(0xFF0C4A6E).withValues(alpha: 0.45)
            : const Color(0xFF450A0A).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quota ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFF7F1D1D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                quota ? Icons.bolt_rounded : Icons.error_outline_rounded,
                size: 18,
                color: quota ? const Color(0xFF38BDF8) : const Color(0xFFF87171),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayMsg,
                  style: TextStyle(
                    color: quota ? const Color(0xFFBAE6FD) : const Color(0xFFFECACA),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (quota) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => showBillingPlanSheet(context, ReferralConn(uid: Session.instance.uid)),
              icon: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF38BDF8)),
              label: const Text(
                'Upgrade plan',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _callControls({required bool on}) {
    if (!on) {
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

    return ListenableBuilder(
      listenable: Listenable.merge([
        _session.micMuted,
        _session.cameraActive,
        _session.activeAttachmentName,
        _session.speakerOn,
      ]),
      builder: (context, _) {
        final muted = _session.micMuted.value;
        final speakerOn = _session.speakerOn.value;
        final camActive = _session.cameraActive.value;
        final hasAttachment = _session.activeAttachmentName.value != null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mic mute toggle
            _controlCircleButton(
              icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: muted ? 'Unmute' : 'Mute',
              active: muted,
              activeColor: const Color(0xFFEF4444),
              onTap: _session.toggleMicMute,
            ),
            const SizedBox(width: 12),
            // Loudspeaker toggle
            _controlCircleButton(
              icon: speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              label: speakerOn ? 'Speaker' : 'Earpiece',
              active: speakerOn,
              activeColor: const Color(0xFF10B981),
              onTap: _session.toggleSpeaker,
            ),
            const SizedBox(width: 12),
            // Media attachment (Klip)
            _controlCircleButton(
              icon: Icons.attach_file_rounded,
              label: _tr('live.attach.clip', 'Clip'),
              active: hasAttachment,
              activeColor: const Color(0xFF38BDF8),
              onTap: _pickAndAttachMedia,
            ),
            const SizedBox(width: 12),
            // Camera video toggle
            _controlCircleButton(
              icon: camActive ? Icons.videocam_rounded : Icons.videocam_outlined,
              label: camActive ? 'Video On' : 'Video',
              active: camActive,
              activeColor: const Color(0xFF3B82F6),
              onTap: () async {
                await _session.toggleCamera();
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(width: 12),
            // End call
            _roundCallButton(
              color: const Color(0xFFDC2626),
              icon: Icons.call_end_rounded,
              size: 58,
              onTap: _hangup,
            ),
          ],
        );
      },
    );
  }

  Widget _controlCircleButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: active ? activeColor.withValues(alpha: 0.18) : const Color(0xFF27272A),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? activeColor : const Color(0xFF3F3F46),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: active ? activeColor : const Color(0xFFD4D4D8),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : const Color(0xFFA1A1AA),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

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
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: size <= 64 ? 28 : 34),
          ),
        ),
      );

  static String _tr(String key, String fallback) {
    final v = CatalogTranslationCache.instance.t(key).trim();
    return v.isNotEmpty ? v : fallback;
  }

  Future<void> _pickAndAttachMedia() async {
    if (!mounted || !_session.connected.value) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _tr('live.attach.title', 'Attach media or document'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF38BDF8), size: 22),
                ),
                title: Text(
                  _tr('live.attach.photo', 'Photo'),
                  style: const TextStyle(color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(ctx, 'photo'),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF34D399), size: 22),
                ),
                title: Text(
                  _tr('live.attach.file', 'Document'),
                  style: const TextStyle(color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    try {
      if (choice == 'photo') {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (xfile == null || !mounted) return;
        final bytes = await xfile.readAsBytes();
        if (bytes.isEmpty) return;
        final name = xfile.name.isNotEmpty ? xfile.name : 'photo.jpg';
        final mime = mimeForFilename(name);
        _session.sendMediaAttachment(name: name, mimeType: mime, bytes: bytes);
      } else if (choice == 'file') {
        final result = await FilePicker.platform.pickFiles(withData: false);
        if (result == null || result.files.isEmpty || !mounted) return;
        final pf = result.files.first;
        final bytes = await platformFileBytes(pf);
        if (bytes == null || bytes.isEmpty) return;
        final name = pf.name.isNotEmpty ? pf.name : 'document';
        final mime = mimeForFilename(name);
        _session.sendMediaAttachment(name: name, mimeType: mime, bytes: bytes);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[PageLiveCall] pickAndAttachMedia error: $e');
    }
  }
}
