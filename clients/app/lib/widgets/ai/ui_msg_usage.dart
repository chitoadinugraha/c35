import 'dart:async';

import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const uiMsgUsageColor = Color(0xFF71717A);

class UiMsgUsage extends StatelessWidget {
  const UiMsgUsage({super.key, required this.msg, this.streaming = false, this.alwaysShow = false, this.showTimestamp = false, this.trailing = false, this.billingCurrency = moneyDefaultCurrency, this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd});
  final MsgRow msg;
  final bool streaming;
  final bool alwaysShow;
  final bool showTimestamp;
  final bool trailing;
  final String billingCurrency;
  final int fxMicroPerUsd;

  static const style = TextStyle(color: uiMsgUsageColor, fontSize: 11, height: 1, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]);
  static const _style = style;
  static const _sepStyle = TextStyle(color: Color(0xFF52525B), fontSize: 10, height: 1, fontWeight: FontWeight.w500);

  static Widget _sep() => const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text('·', style: _sepStyle));

  static void _addPart(List<Widget> parts, Widget child) {
    if (parts.isNotEmpty) parts.add(_sep());
    parts.add(child);
  }

  bool _show(MsgUsageStats stats) {
    if (msg.role == 'user' || msg.role == 'system' || streaming) return false;
    if (alwaysShow) {
      return stats.hasData || showTimestamp && msg.createdAtMs > 0 || msg.reqId.isNotEmpty;
    }
    return PromptUsagePrefs.instance.showUsageStats &&
        (stats.hasData || (showTimestamp && msg.createdAtMs > 0));
  }

  (String, int) _walletMoney() {
    final billing = AppStore.instance.billing;
    if (billing != null) {
      return (
        billingPrimaryCurrency(billing),
        billing.hasFxMicroPerUsd() ? billing.fxMicroPerUsd.toInt() : fxMicroPerUsd,
      );
    }
    final wallet = AppStore.instance.wallet;
    return (wallet.billingCurrency, wallet.fxMicroPerUsd);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([PromptUsagePrefs.instance, AppStore.instance]),
        builder: (context, _) {
          final stats = msgUsageStats(msg);
          if (!_show(stats)) return const SizedBox.shrink();
          final (currency, fx) = _walletMoney();
          final timeLabel = showTimestamp && msg.createdAtMs > 0 ? chatMsgTimeLabel(msg.createdAtMs) : '';
          final usageMs = uiFmtDurationMs(stats.durationMs);
          final price = moneyCostLabel(stats.costUsd, currency: currency, fxMicroPerUsd: fx);
          final modelLabel = stats.model.isNotEmpty && stats.model != 'local' ? traceModelLabel(stats.model) : '';
          final tooltipParts = <String>[
            if (modelLabel.isNotEmpty) modelLabel,
            if (stats.tokensIn > 0) '${uiFmtGroupedInt(stats.tokensIn)} in',
            if (stats.tokensOut > 0) '${uiFmtGroupedInt(stats.tokensOut)} out',
            if (usageMs.isNotEmpty) usageMs,
            if (price.isNotEmpty) price,
          ];
          final tooltip = tooltipParts.join(' · ');
          final parts = <Widget>[];
          if (stats.model == 'local' && stats.tokensIn == 0 && stats.tokensOut == 0 && stats.costUsd == 0 && stats.durationMs > 0) {
            _addPart(parts, const Text('local · free', style: _style));
          }
          if (modelLabel.isNotEmpty) _addPart(parts, Text(modelLabel, style: _style));
          if (timeLabel.isNotEmpty) _addPart(parts, Text(timeLabel, style: _style));
          if (stats.tokensIn > 0) {
            _addPart(
              parts,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 11, color: uiMsgUsageColor),
                  const SizedBox(width: 2),
                  Text(uiFmtGroupedInt(stats.tokensIn), style: _style),
                ],
              ),
            );
          }
          if (stats.tokensOut > 0) {
            _addPart(
              parts,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 11, color: uiMsgUsageColor),
                  const SizedBox(width: 2),
                  Text(uiFmtGroupedInt(stats.tokensOut), style: _style),
                ],
              ),
            );
          }
          if (usageMs.isNotEmpty) _addPart(parts, Text(usageMs, style: _style));
          if (price.isNotEmpty) _addPart(parts, Text(price, style: _style));
          final row = Padding(
            padding: trailing ? EdgeInsets.zero : const EdgeInsets.only(top: 6),
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: parts),
          );
          final visibleParts = <String>[
            if (stats.model == 'local' && stats.tokensIn == 0 && stats.tokensOut == 0 && stats.costUsd == 0 && stats.durationMs > 0) 'local · free',
            if (modelLabel.isNotEmpty) modelLabel,
            if (stats.tokensIn > 0) '${uiFmtGroupedInt(stats.tokensIn)} in',
            if (stats.tokensOut > 0) '${uiFmtGroupedInt(stats.tokensOut)} out',
            if (usageMs.isNotEmpty) usageMs,
            if (price.isNotEmpty) price,
          ];
          final visibleLabel = visibleParts.join(' · ');
          final showTip = tooltip.isNotEmpty && tooltip != visibleLabel && !(visibleParts.length == 1 && visibleParts.first == tooltip);
          final child = showTip ? uiTooltip(message: tooltip, child: row) : row;
          return Align(alignment: Alignment.centerLeft, child: ExcludeSemantics(child: child));
        },
      );
}

/// Fills usage from turn trace when [MsgRow] has req_id but zero tokens (channel / bot_peer).
class UiMsgUsageWithTrace extends StatefulWidget {
  const UiMsgUsageWithTrace({
    super.key,
    required this.conn,
    required this.msg,
    this.streaming = false,
    this.showTimestamp = false,
    this.trailing = false,
    this.alwaysShow = false,
    this.billingCurrency = moneyDefaultCurrency,
    this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd,
  });

  final ChatConn conn;
  final MsgRow msg;
  final bool streaming;
  final bool showTimestamp;
  final bool trailing;
  final bool alwaysShow;
  final String billingCurrency;
  final int fxMicroPerUsd;

  @override
  State<UiMsgUsageWithTrace> createState() => _UiMsgUsageWithTraceState();
}

class _UiMsgUsageWithTraceState extends State<UiMsgUsageWithTrace> {
  MsgRow? _enriched;
  StreamSubscription<String>? _traceSub;

  @override
  void initState() {
    super.initState();
    _traceSub = widget.conn.onTraceCachePut.listen((reqId) {
      if (reqId == widget.msg.reqId.trim()) _applyFromCache();
    });
    unawaited(_loadTrace());
  }

  @override
  void didUpdateWidget(covariant UiMsgUsageWithTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msg.id != widget.msg.id || oldWidget.msg.reqId != widget.msg.reqId) {
      _enriched = null;
      unawaited(_loadTrace());
    }
  }

  @override
  void dispose() {
    unawaited(_traceSub?.cancel());
    super.dispose();
  }

  MsgRow _effective() => _enriched ?? widget.msg;

  void _applyFromCache() {
    final reqId = widget.msg.reqId.trim();
    if (reqId.isEmpty) return;
    final view = buildTraceView(widget.conn.traceCacheGet(reqId));
    if (view.totals.tokensIn <= 0 && view.totals.tokensOut <= 0 && view.totals.durationMs <= 0) return;
    setState(() => _enriched = _mergeTotals(widget.msg, view.totals));
  }

  MsgRow _mergeTotals(MsgRow base, TraceTotals totals) => base.copyWith(
        tokensIn: base.tokensIn > 0 ? base.tokensIn : totals.tokensIn,
        tokensOut: base.tokensOut > 0 ? base.tokensOut : totals.tokensOut,
        durationMs: base.durationMs > 0 ? base.durationMs : totals.durationMs,
        costUsd: base.costUsd > 0 ? base.costUsd : totals.costUsd,
        model: base.model.isNotEmpty ? base.model : totals.model,
      );

  Future<void> _loadTrace() async {
    final m = widget.msg;
    if (m.reqId.trim().isEmpty || m.role != 'assistant') return;
    final stats = msgUsageStats(m);
    if (stats.hasData) return;
    await widget.conn.tracePrefetch(m.reqId);
    if (!mounted) return;
    _applyFromCache();
    if (_enriched != null) return;
    try {
      final view = await widget.conn.traceViewFetch(m.reqId);
      if (!mounted) return;
      if (view.totals.tokensIn <= 0 && view.totals.tokensOut <= 0 && view.totals.durationMs <= 0) return;
      setState(() => _enriched = _mergeTotals(m, view.totals));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => UiMsgUsage(
        msg: _effective(),
        streaming: widget.streaming,
        showTimestamp: widget.showTimestamp,
        trailing: widget.trailing,
        alwaysShow: widget.alwaysShow,
        billingCurrency: widget.billingCurrency,
        fxMicroPerUsd: widget.fxMicroPerUsd,
      );
}
