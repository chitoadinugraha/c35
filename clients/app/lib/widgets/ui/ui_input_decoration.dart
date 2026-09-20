import 'package:flutter/material.dart';

class UiInputDecoration {
  const UiInputDecoration._();

  static const kRadius = 10.0;
  static const kFieldContentPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 13);

  static OutlineInputBorder borderOf(
    ColorScheme c, {
    double radius = kRadius,
    Color? color,
    double width = 1,
  }) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color ?? c.outlineVariant.withValues(alpha: 0.38), width: width),
      );

  static Color fillColorOf(ThemeData theme) {
    final c = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? const Color(0xFF17171C)
        : c.surfaceContainerHighest.withValues(alpha: 0.55);
  }

  static Color enabledBorderColorOf(ThemeData theme) =>
      theme.brightness == Brightness.dark ? const Color(0xFF26262E) : theme.colorScheme.outlineVariant.withValues(alpha: 0.38);

  static InputDecoration of(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? prefix,
    String? prefixText,
    Widget? suffix,
    Widget? suffixIcon,
    String? suffixText,
    bool alignLabelWithHint = false,
    EdgeInsetsGeometry? contentPadding,
    BoxConstraints? prefixIconConstraints,
    BoxConstraints? suffixIconConstraints,
    bool isDense = false,
    bool floatingLabel = true,
  }) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final enabledColor = enabledBorderColorOf(theme);
    final enabled = borderOf(c, color: enabledColor);
    final focused = borderOf(c, color: c.primary.withValues(alpha: 0.85), width: 1.5);
    final error = borderOf(c, color: c.error);

    return InputDecoration(
      labelText: floatingLabel ? labelText : null,
      hintText: hintText,
      prefixIcon: prefixIcon,
      prefix: prefix,
      prefixText: prefixText,
      prefixStyle: prefixText != null
          ? theme.textTheme.bodyLarge?.copyWith(
              color: c.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            )
          : null,
      suffix: suffix,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: suffixText != null
          ? theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)
          : null,
      alignLabelWithHint: alignLabelWithHint,
      isDense: isDense,
      contentPadding: contentPadding ?? kFieldContentPadding,
      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,
      filled: true,
      fillColor: fillColorOf(theme),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.65)),
      floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
        color: c.primary,
        fontWeight: FontWeight.w500,
      ),
      border: enabled,
      enabledBorder: enabled,
      focusedBorder: focused,
      errorBorder: error,
      focusedErrorBorder: borderOf(c, color: c.error, width: 1.5),
    );
  }
}
