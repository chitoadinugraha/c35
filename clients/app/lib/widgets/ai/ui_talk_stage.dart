import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/expense/expense_api.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:flutter/material.dart';

class UiTalkStage extends StatelessWidget {
  const UiTalkStage({
    super.key,
    required this.assistant,
    required this.userText,
    required this.listening,
    required this.busy,
    required this.speakEnabled,
    required this.onMic,
    required this.onSpeak,
    required this.onAttach,
    required this.onModel,
    this.blocks = const [],
    this.usage,
    this.consumptionApi,
    this.expenseApi,
    this.locale = 'en-US',
    this.onConsumptionSaved,
    this.onExpenseSaved,
    this.onBlockCollapsedChanged,
    this.onImageUpgradeHd,
    this.onMediaRegenerate,
    this.stagedCount = 0,
    this.modelProvider = 'alienai',
    this.modelAccent,
    this.welcome,
  });

  final MsgRow? assistant;
  final String userText;
  final bool listening;
  final bool busy;
  final bool speakEnabled;
  final VoidCallback onMic;
  final VoidCallback onSpeak;
  final VoidCallback onAttach;
  final VoidCallback onModel;
  final List<ChatBlock> blocks;
  final MsgUsageStats? usage;
  final ConsumptionApi? consumptionApi;
  final ExpenseApi? expenseApi;
  final String locale;
  final ConsumptionBlockSaved? onConsumptionSaved;
  final ExpenseBlockSaved? onExpenseSaved;
  final BlockCollapsedChanged? onBlockCollapsedChanged;
  final void Function(ChatBlock block)? onImageUpgradeHd;
  final MediaRegenerateHandler? onMediaRegenerate;
  final int stagedCount;
  final String modelProvider;
  final Color? modelAccent;
  final Widget? welcome;

  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFF71717A);
  static const _user = Color(0xFFA1A1AA);
  static const _line = Color(0xFF27272A);
  static const _chip = Color(0xFF18181B);
  static const _accent = Color(0xFF06B6D4);
  static const _stop = Color(0xFFEF4444);
  static const _speakOnBg = Color(0xFF27272A);
  static const _speakOnBorder = Color(0xFF52525B);

  @override
  Widget build(BuildContext context) {
    final row = assistant;
    final assistantText = row == null ? '' : msgDisplayContent(row).trim();
    final showWelcome = welcome != null && assistantText.isEmpty && !busy;
    final placeholder = assistantText.isEmpty && listening ? 'Listening' : assistantText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: showWelcome ? _welcomeBody() : _answer(row, placeholder, assistantText.isEmpty && listening)),
        _usageLine(),
        if (userText.trim().isNotEmpty) _transcript(),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, uiSafeBottomInset(context, 16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Align(alignment: Alignment.centerLeft, child: _side(onPressed: onAttach, icon: Icons.attach_file_rounded, tooltip: 'Attach', badge: stagedCount))),
              Expanded(child: Center(child: _mic())),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _speakButton(),
                      const SizedBox(width: 10),
                      _side(
                        onPressed: onModel,
                        tooltip: 'Model',
                        child: UiAssistantProviderIcon(provider: modelProvider, size: 20, accent: modelAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _welcomeBody() => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (constraints.maxHeight - 20).clamp(0, double.infinity)),
            child: Center(child: welcome),
          ),
        ),
      );

  Widget _answer(MsgRow? row, String text, bool placeholder) {
    final short = !text.contains('\n') && text.length < 90;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (constraints.maxHeight - 20).clamp(0, double.infinity)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  text,
                  textAlign: short ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontSize: placeholder || short ? 26 : 20,
                    height: 1.35,
                    color: placeholder ? _muted : _text,
                    fontWeight: placeholder ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (blocks.isNotEmpty && row != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: UiMsgBlocks(
                      msgId: row.id,
                      blocks: blocks,
                      consumptionApi: consumptionApi,
                      expenseApi: expenseApi,
                      locale: locale,
                      onConsumptionSaved: onConsumptionSaved,
                      onExpenseSaved: onExpenseSaved,
                      onBlockCollapsedChanged: onBlockCollapsedChanged,
                      onImageUpgradeHd: onImageUpgradeHd,
                      onMediaRegenerate: onMediaRegenerate,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transcript() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _chip,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: listening ? _accent : _line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _transcriptBody(),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _transcriptBody() => Text(
        userText.trim(),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _user, fontSize: 14, height: 1.35),
      );

  Widget _mic() {
    final color = busy ? _stop : (listening ? _accent : _text);
    final iconColor = busy || listening ? _text : const Color(0xFF18181B);
    return Tooltip(
      message: busy ? 'Stop' : 'Mic',
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onMic,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(busy ? Icons.stop_rounded : Icons.mic_rounded, size: 30, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _speakButton() => Tooltip(
        message: 'Speak',
        child: Material(
          color: speakEnabled ? _speakOnBg : _chip,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onSpeak,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: speakEnabled ? _speakOnBorder : _line, width: speakEnabled ? 1.5 : 1),
              ),
              child: Icon(
                speakEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 21,
                color: speakEnabled ? _text : _muted,
              ),
            ),
          ),
        ),
      );

  Widget _side({required VoidCallback onPressed, IconData? icon, Widget? child, required String tooltip, bool active = false, int badge = 0}) => Tooltip(
        message: tooltip,
        child: Material(
          color: _chip,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? _accent : _line),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child ?? Icon(icon ?? Icons.circle, size: 20, color: active ? _accent : _user),
                  if (badge > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _usageLine() => ListenableBuilder(
        listenable: PromptUsagePrefs.instance,
        builder: (context, _) {
          if (busy) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text('Thinking...', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
            );
          }
          if (listening) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text('Listening...', textAlign: TextAlign.center, style: TextStyle(color: _accent, fontSize: 12)),
            );
          }
          final stats = usage;
          if (PromptUsagePrefs.instance.showUsageStats && stats != null && stats.hasData) {
            final duration = uiFmtDurationMs(stats.durationMs);
            final text = duration.isEmpty
                ? '${uiFmtGroupedInt(stats.tokensIn)} in · ${uiFmtGroupedInt(stats.tokensOut)} out'
                : '${uiFmtGroupedInt(stats.tokensIn)} in · ${uiFmtGroupedInt(stats.tokensOut)} out · $duration';
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
            );
          }
          return const SizedBox(height: 4);
        },
      );
}
