import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _titleStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5));
const _subtitleStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF71717A), height: 1.1);

class UiPageBar extends StatelessWidget {
  const UiPageBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? trailing;

  bool get _hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  Widget _titleArea() {
    if (titleWidget != null) return titleWidget!;
    if (!_hasSubtitle) {
      return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStyle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStyle),
        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _subtitleStyle),
      ],
    );
  }

  static const _backBtnStyle = ButtonStyle(
    visualDensity: VisualDensity.compact,
    padding: WidgetStatePropertyAll(EdgeInsets.zero),
    minimumSize: WidgetStatePropertyAll(Size(32, 32)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              if (onBack != null)
                uiIconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFFA1A1AA)),
                  style: _backBtnStyle,
                ),
              if (onBack != null) const SizedBox(width: 8),
              Expanded(child: _titleArea()),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}
