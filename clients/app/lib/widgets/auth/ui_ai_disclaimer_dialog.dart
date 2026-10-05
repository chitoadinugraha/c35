import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/settings/ai_disclaimer_prefs.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UiAiDisclaimerDialog extends StatelessWidget {
  const UiAiDisclaimerDialog({super.key});

  static Future<void> show(BuildContext context) => uiDialogShow<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const UiAiDisclaimerDialog(),
      );

  static Uri get _termsUri {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$origin/terms.html');
  }

  Future<void> _accept(BuildContext context) async {
    await AiDisclaimerPrefs.instance.acknowledgePut();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _openTerms() async {
    final uri = _termsUri;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.45);
    final linkStyle = bodyStyle.copyWith(color: uiDialogAccent, decoration: TextDecoration.underline);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('legal.aiDisclaimerAccuracy'.tr(), style: bodyStyle),
            const SizedBox(height: 12),
            Text('legal.aiDisclaimerResponsibility'.tr(), style: bodyStyle),
            const SizedBox(height: 14),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('legal.aiDisclaimerTermsPrefix'.tr(), style: bodyStyle),
                GestureDetector(
                  onTap: _openTerms,
                  child: Text('legal.aiDisclaimerTermsLink'.tr(), style: linkStyle),
                ),
                Text('legal.aiDisclaimerTermsSuffix'.tr(), style: bodyStyle),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => _accept(context),
          child: Text('legal.aiDisclaimerAccept'.tr()),
        ),
      ],
    );
  }
}
