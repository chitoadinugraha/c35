import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const uiDialogBg = Color(0xFF18181B);
const uiDialogBorder = Color(0xFF27272A);
const uiDialogTitleColor = Color(0xFFF4F4F5);
const uiDialogMuted = Color(0xFF71717A);
const uiDialogAccent = Color(0xFF34D399);

const uiDialogInset = EdgeInsets.fromLTRB(20, 16, 12, 20);
const uiDialogInsetCompact = EdgeInsets.fromLTRB(16, 12, 8, 12);

Future<T?> uiDialogShow<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) =>
    showDialog<T>(context: context, barrierDismissible: barrierDismissible, builder: builder);

class UiDialog extends StatelessWidget {
  const UiDialog({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.maxWidth,
    this.padding = uiDialogInset,
    this.inset = true,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    var body = child;
    if (inset && padding != null) body = Padding(padding: padding!, child: body);
    if (width != null || height != null) body = SizedBox(width: width, height: height, child: body);
    return Dialog(
      backgroundColor: uiDialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: uiDialogBorder)),
      child: maxWidth != null ? ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: body) : body,
    );
  }
}

class UiDialogClose extends StatelessWidget {
  const UiDialogClose({super.key, this.onPressed, this.enabled = true});

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => uiIconButton(
        tooltip: 'Close',
        visualDensity: VisualDensity.compact,
        onPressed: enabled ? (onPressed ?? () => Navigator.pop(context)) : null,
        icon: const Icon(Icons.close, color: uiDialogMuted, size: 20),
      );
}

class UiDialogHeader extends StatelessWidget {
  const UiDialogHeader({super.key, required this.title, this.onClose, this.closeEnabled = true, this.titleStyle});

  final String title;
  final VoidCallback? onClose;
  final bool closeEnabled;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? const TextStyle(color: uiDialogTitleColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          UiDialogClose(onPressed: onClose, enabled: closeEnabled),
        ],
      );
}

InputDecoration uiDialogSearchDecoration({required String hintText}) => InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: uiDialogMuted),
      prefixIcon: const Icon(Icons.search, size: 18, color: uiDialogMuted),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF100F12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: uiDialogBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: uiDialogBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: uiDialogAccent)),
    );

class UiDialogSearchHeader extends StatelessWidget {
  const UiDialogSearchHeader({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = true,
    this.onClose,
    this.closeEnabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onClose;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              style: const TextStyle(color: uiDialogTitleColor, fontSize: 13),
              decoration: uiDialogSearchDecoration(hintText: hintText),
              onChanged: onChanged,
            ),
          ),
          UiDialogClose(onPressed: onClose, enabled: closeEnabled),
        ],
      );
}