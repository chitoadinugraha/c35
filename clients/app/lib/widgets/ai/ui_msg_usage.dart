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

  static const _style = TextStyle(color: uiMsgUsageColor, fontSize: 11, height: 1, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]);

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
            if (stats.tokensIn > 0) '${uiFmtGroupedInt(stats.tokensIn)} in',
            if (stats.tokensOut > 0) '${uiFmtGroupedInt(stats.tokensOut)} out',
            if (usageMs.isNotEmpty) usageMs,
            if (price.isNotEmpty) price,
            if (modelLabel.isNotEmpty) modelLabel,
          ];
          final tooltip = tooltipParts.join(' · ');
          final hasUsageMeta = stats.tokensIn > 0 || stats.tokensOut > 0 || usageMs.isNotEmpty || price.isNotEmpty;
          final row = Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (stats.model == 'local' && stats.tokensIn == 0 && stats.tokensOut == 0 && stats.costUsd == 0 && stats.durationMs > 0) ...[
                  const Text('local · free', style: _style),
                  const SizedBox(width: 6),
                ],
                if (stats.tokensIn > 0) ...[
                  const Icon(Icons.arrow_upward_rounded, size: 11, color: uiMsgUsageColor),
                  const SizedBox(width: 1),
                  Text(uiFmtGroupedInt(stats.tokensIn), style: _style),
                ],
                if (stats.tokensIn > 0 && stats.tokensOut > 0) const SizedBox(width: 6),
                if (stats.tokensOut > 0) ...[
                  const Icon(Icons.arrow_downward_rounded, size: 11, color: uiMsgUsageColor),
                  const SizedBox(width: 1),
                  Text(uiFmtGroupedInt(stats.tokensOut), style: _style),
                ],
                if (usageMs.isNotEmpty) ...[
                  if (stats.tokensIn > 0 || stats.tokensOut > 0) const SizedBox(width: 6),
                  Text(usageMs, style: _style),
                ],
                if (price.isNotEmpty) ...[
                  if (hasUsageMeta) const SizedBox(width: 6),
                  Text(price, style: _style),
                ],
                if (modelLabel.isNotEmpty) ...[
                  if (hasUsageMeta || price.isNotEmpty) const SizedBox(width: 6),
                  Text(modelLabel, style: _style),
                ],
              ],
            ),
          );
          final visibleParts = <String>[
            if (stats.model == 'local' && stats.tokensIn == 0 && stats.tokensOut == 0 && stats.costUsd == 0 && stats.durationMs > 0) 'local · free',
            if (stats.tokensIn > 0) uiFmtGroupedInt(stats.tokensIn),
            if (stats.tokensOut > 0) uiFmtGroupedInt(stats.tokensOut),
            if (usageMs.isNotEmpty) usageMs,
            if (price.isNotEmpty) price,
            if (modelLabel.isNotEmpty) modelLabel,
          ];
          final visibleLabel = visibleParts.join(' ');
          final showTip = tooltip.isNotEmpty && tooltip != visibleLabel && !(visibleParts.length == 1 && visibleParts.first == tooltip);
          return Align(
            alignment: Alignment.centerLeft,
            child: showTip ? uiTooltip(message: tooltip, child: row) : row,
          );
        },
      );
}
