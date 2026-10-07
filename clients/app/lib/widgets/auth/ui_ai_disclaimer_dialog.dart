import 'dart:async';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/locale/app_locale.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UiAiDisclaimerResult {
  const UiAiDisclaimerResult({required this.locationOptIn});

  final bool locationOptIn;
}

class UiAiDisclaimerDialog extends StatefulWidget {
  const UiAiDisclaimerDialog({super.key, required this.needTerms, required this.needLocation});

  final bool needTerms;
  final bool needLocation;

  static Future<UiAiDisclaimerResult?> show(
    BuildContext context, {
    required bool needTerms,
    required bool needLocation,
  }) =>
      uiDialogShow<UiAiDisclaimerResult>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => UiAiDisclaimerDialog(needTerms: needTerms, needLocation: needLocation),
      );

  static Uri get termsUri {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$origin/terms.html');
  }

  @override
  State<UiAiDisclaimerDialog> createState() => _UiAiDisclaimerDialogState();
}

class _UiAiDisclaimerDialogState extends State<UiAiDisclaimerDialog> {
  var _termsChecked = false;
  var _locationChecked = false;

  bool get _canContinue =>
      (!widget.needTerms || _termsChecked) && (!widget.needLocation || _locationChecked);

  Future<void> _openTerms() async {
    final uri = UiAiDisclaimerDialog.termsUri;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _localePick(Locale locale) async {
    if (appLocaleSame(locale, context.locale)) return;
    await context.setLocale(locale);
    if (mounted) setState(() {});
  }

  void _continue() {
    if (!_canContinue) return;
    Navigator.of(context).pop(UiAiDisclaimerResult(locationOptIn: widget.needLocation && _locationChecked));
  }

  Widget _termsCheckboxTitle(TextStyle bodyStyle) {
    final linkStyle = bodyStyle.copyWith(color: uiDialogAccent);
    return RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(text: 'legal.aiDisclaimerCheckTermsPrefix'.tr()),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: TextButton(
              onPressed: _openTerms,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: uiDialogAccent,
                textStyle: linkStyle,
              ),
              child: Text('legal.aiDisclaimerTermsLink'.tr()),
            ),
          ),
          TextSpan(text: 'legal.aiDisclaimerCheckTermsSuffix'.tr()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.45);
    final locale = context.locale;
    return AlertDialog(
      backgroundColor: uiDialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: uiDialogBorder)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'legal.aiDisclaimerTitle'.tr(),
              style: const TextStyle(color: uiDialogTitleColor, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('settings.language'.tr(), style: bodyStyle.copyWith(fontSize: 12, color: uiDialogMuted)),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: uiDialogBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: appLocales.any((e) => appLocaleSame(e.locale, locale)) ? locale : appLocales.first.locale,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  dropdownColor: uiDialogBg,
                  style: const TextStyle(color: uiDialogTitleColor, fontSize: 14),
                  icon: const Icon(Icons.expand_more, color: uiDialogMuted),
                  items: appLocales
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.locale,
                          child: Row(
                            children: [
                              UiImg(src: e.flag, width: 20, height: 20, recolor: false),
                              const SizedBox(width: 10),
                              Text(e.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (loc) {
                    if (loc != null) unawaited(_localePick(loc));
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('legal.aiDisclaimerIntro'.tr(), style: bodyStyle),
            const SizedBox(height: 8),
            if (widget.needTerms)
              CheckboxListTile(
                value: _termsChecked,
                onChanged: (v) => setState(() => _termsChecked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: uiDialogAccent,
                title: _termsCheckboxTitle(bodyStyle),
              ),
            if (widget.needLocation)
              CheckboxListTile(
                value: _locationChecked,
                onChanged: (v) => setState(() => _locationChecked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: uiDialogAccent,
                title: Text('legal.aiDisclaimerCheckLocation'.tr(), style: bodyStyle),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: _canContinue ? _continue : null, child: Text('legal.aiDisclaimerContinue'.tr())),
      ],
    );
  }
}
