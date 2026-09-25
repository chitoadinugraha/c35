import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const uiMsgUsageColor = Color(0xFF71717A);

class UiMsgUsage extends StatelessWidget {
  const UiMsgUsage({super.key, required this.msg, this.streaming = false, this.billingCurrency = moneyDefaultCurrency, this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd});
  final MsgRow msg;
  final bool streaming;
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

  bool _show(MsgUsageStats stats) =>
      PromptUsagePrefs.instance.showUsageStats &&
      msg.role != 'user' &&
      msg.role != 'system' &&
      !streaming &&
      (stats.tokensIn > 0 || stats.tokensOut > 0 || stats.durationMs > 0 || stats.costUsd > 0 || (stats.model == 'local' && stats.durationMs > 0));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PromptUsagePrefs.instance,
        builder: (context, _) {
          final stats = msgUsageStats(msg);
          if (!_show(stats)) return const SizedBox.shrink();
          final usageMs = uiFmtDurationMs(stats.durationMs);
          final price = moneyCostLabel(stats.costUsd, currency: billingCurrency, fxMicroPerUsd: fxMicroPerUsd);
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
            padding: const EdgeInsets.only(top: 6),
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
