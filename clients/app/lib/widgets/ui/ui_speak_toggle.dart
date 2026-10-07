import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/hint/hint_chip_theme.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

String homeTalkSurfaceLabel(bool talkEnabled) {
  final key = talkEnabled ? 'home.chatMode' : 'home.talkMode';
  final t = catalogT(key);
  if (t != key) return t;
  return talkEnabled ? 'Chat Mode' : 'Talk Mode';
}

const _menuPadH = 12.0;
const _talkActiveBorder = Color(0xFF06B6D4);
const _talkActiveBg = Color(0xFF164E63);

class UiTalkCallToggleRow extends StatelessWidget {
  const UiTalkCallToggleRow({
    super.key,
    required this.talkEnabled,
    required this.onTalkTap,
    this.callChip,
  });

  final bool talkEnabled;
  final VoidCallback? onTalkTap;
  final Widget? callChip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_menuPadH, 10, _menuPadH, 10),
        child: Row(
          children: [
            Expanded(
              flex: 9,
              child: _UiTalkModeChip(active: talkEnabled, onTap: onTalkTap),
            ),
            if (callChip != null) ...[
              const SizedBox(width: 8),
              Expanded(flex: 11, child: callChip!),
            ],
          ],
        ),
      );
}

class _UiTalkModeChip extends StatelessWidget {
  const _UiTalkModeChip({required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final idle = HintChipTheme.liveCall;
    final border = active ? _talkActiveBorder : idle.border;
    final bg = active ? _talkActiveBg : idle.background;
    final iconColor = active ? const Color(0xFFFAFAFA) : idle.icon;
    final labelColor = active ? const Color(0xFFFAFAFA) : idle.label;
    final label = homeTalkSurfaceLabel(active);
    return uiTooltip(
      message: active ? homeTalkSurfaceLabel(false) : label,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: border)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(active ? Icons.chat_bubble_outline_rounded : Icons.mic_rounded, size: 15, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UiAppToggle extends StatelessWidget {
  const UiAppToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: value ? const Color(0xFF22C55E) : const Color(0xFF27272A),
            border: Border.all(color: value ? const Color(0xFF16A34A) : const Color(0xFF3F3F46)),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFFFFF),
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      );
}
