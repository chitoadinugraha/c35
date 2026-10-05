import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/live/live_call_session.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/settings/live_call_prefs.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_live_offer_icon.dart';
import 'package:flutter/material.dart';

class PageLiveCall extends StatefulWidget {
  const PageLiveCall({super.key, required this.conn, required this.offer});

  final ChatConn conn;
  final LiveOffer offer;

  @override
  State<PageLiveCall> createState() => _PageLiveCallState();
}

class _PageLiveCallState extends State<PageLiveCall> {
  late final LiveCallSession _session = LiveCallSession();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _session.error.removeListener(_onSessionError);
    _session.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.conn.liveStart(offerId: widget.offer.id);
      if (res.error.isNotEmpty) {
        setState(() => _error = res.error);
      } else {
        await LiveCallPrefs.setLastOfferId(widget.offer.id);
        await _session.connect(res);
        _session.error.addListener(_onSessionError);
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
        listenable: Listenable.merge([AppStore.instance, _session.connected, _session.ready]),
        builder: (context, _) {
          final wallet = AppStore.instance.wallet;
          final price = liveOfferPricePerMinLocal(
            widget.offer,
            currency: wallet.billingCurrency,
            fxMicroPerUsd: wallet.fxMicroPerUsd,
          );
          final on = _session.connected.value;
          final ready = _session.ready.value;
          final status = on
              ? (ready ? 'Connected — speak naturally' : 'Connecting to voice…')
              : (widget.offer.enabled ? 'Voice call · billed per minute' : liveOfferSoonTag());

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
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 36),
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
                      const Spacer(flex: 2),
                      _avatarRing(on: on, ready: ready),
                      const SizedBox(height: 28),
                      Text(
                        liveOfferLabel(widget.offer),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (price.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Text(
                            price,
                            style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                      if (PromptUsagePrefs.instance.showUsageStats)
                        ValueListenableBuilder<LiveUsage?>(
                          valueListenable: _session.usage,
                          builder: (_, u, __) => u == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${u.totalTokens} tokens · in ${u.promptTokens} · out ${u.responseTokens}',
                                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                  ),
                                ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _errorBanner(_error!),
                      ],
                      const Spacer(flex: 3),
                      _callButton(on: on),
                      const SizedBox(height: 10),
                      Text(
                        on ? 'End call' : (widget.offer.enabled ? 'Start call' : liveOfferSoonTag()),
                        style: const TextStyle(color: Color(0xFF52525B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _avatarRing({required bool on, required bool ready}) {
    final ring = on
        ? (ready ? const Color(0xFF22C55E) : const Color(0xFFEAB308))
        : const Color(0xFF3F3F46);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 3),
        boxShadow: [
          BoxShadow(color: ring.withValues(alpha: 0.25), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF18181B),
        ),
        child: Center(child: UiLiveOfferIcon(offer: widget.offer, size: 56)),
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
