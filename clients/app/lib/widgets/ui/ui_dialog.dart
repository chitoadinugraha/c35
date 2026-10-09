import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const uiDialogBg = Color(0xFF18181B);
const uiDialogBorder = Color(0xFF27272A);
const uiDialogTitleColor = Color(0xFFF4F4F5);
const uiDialogMuted = Color(0xFF71717A);
const uiDialogAccent = Color(0xFF34D399);

const uiDialogInset = EdgeInsets.fromLTRB(20, 16, 12, 20);
const uiDialogInsetCompact = EdgeInsets.fromLTRB(16, 12, 8, 12);
const uiDialogAskBodyInset = EdgeInsets.fromLTRB(16, 0, 8, 12);

const uiDialogAskWidth = 360.0;
const uiDialogAskHeight = 420.0;

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

InputDecoration uiDialogSearchDecoration({required String hintText, Widget? suffixIcon, Widget? prefixIcon}) => InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: uiDialogMuted),
      prefixIcon: prefixIcon ?? const Icon(Icons.search, size: 18, color: uiDialogMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
    this.beforeClose = const [],
    this.searchSuffix,
    this.searchPrefix,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onClose;
  final bool closeEnabled;
  final List<Widget> beforeClose;
  final Widget? searchSuffix;
  final Widget? searchPrefix;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              style: const TextStyle(color: uiDialogTitleColor, fontSize: 13),
              decoration: uiDialogSearchDecoration(hintText: hintText, suffixIcon: searchSuffix, prefixIcon: searchPrefix),
              onChanged: onChanged,
            ),
          ),
          if (searchSuffix != null) const SizedBox(width: 6),
          ...beforeClose.map((w) => uiDialogHeaderAction(w)),
          uiDialogHeaderAction(UiDialogClose(onPressed: onClose, enabled: closeEnabled)),
        ],
      );
}

/// Keeps search-field trailing icons (+, close) vertically aligned with the field.
Widget uiDialogHeaderAction(Widget child) => SizedBox(height: 40, child: Center(child: child));

/// Fixed-size search + list shell shared by [ioAskItemsShow] and async pickers (e.g. sites).
class UiDialogAskShell extends StatelessWidget {
  const UiDialogAskShell({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.body,
    this.onSearchChanged,
    this.searchSuffix,
    this.searchPrefix,
    this.beforeClose = const [],
    this.onClose,
    this.closeEnabled = true,
    this.width = uiDialogAskWidth,
    this.height = uiDialogAskHeight,
    this.dividerBelowHeader = false,
    this.bodyGap = 0,
    this.bodyPadding = uiDialogAskBodyInset,
  });

  final TextEditingController searchController;
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final Widget? searchSuffix;
  final Widget? searchPrefix;
  final List<Widget> beforeClose;
  final VoidCallback? onClose;
  final bool closeEnabled;
  final double width;
  final double height;
  final bool dividerBelowHeader;
  final double bodyGap;
  final EdgeInsetsGeometry bodyPadding;
  final Widget body;

  @override
  Widget build(BuildContext context) => UiDialog(
        width: width,
        height: height,
        padding: EdgeInsets.zero,
        inset: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: uiDialogInsetCompact,
              child: UiDialogSearchHeader(
                controller: searchController,
                hintText: hintText,
                onChanged: onSearchChanged,
                onClose: onClose,
                closeEnabled: closeEnabled,
                beforeClose: beforeClose,
                searchSuffix: searchSuffix,
                searchPrefix: searchPrefix,
              ),
            ),
            if (dividerBelowHeader) const Divider(height: 1, color: uiDialogBorder),
            if (bodyGap > 0) SizedBox(height: bodyGap),
            Expanded(child: Padding(padding: bodyPadding, child: body)),
          ],
        ),
      );
}

Widget uiDialogAskEmptyText(String text) =>
    Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: uiDialogMuted, fontSize: 13)));

Widget uiDialogAskLoading() => const Center(
      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: uiDialogMuted)),
    );