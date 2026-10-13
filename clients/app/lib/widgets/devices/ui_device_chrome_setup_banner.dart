import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:alienai_c35/widgets/devices/ui_device_prompt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _border = Color(0xFF27272A);
const _panel = Color(0xFF18181B);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);
const _accent = Color(0xFF34D399);

/// Prompts install of Chrome + MV3 extension for unified desktop browser automation.
class UiDeviceChromeSetupBanner extends StatelessWidget {
  const UiDeviceChromeSetupBanner({
    super.key,
    required this.deviceName,
    required this.promptStore,
  });

  final String deviceName;
  final DevicePromptContextStore promptStore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chrome automation',
                style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Install Google Chrome and the Alien AI Remote extension on this PC for faster Sheets and site tasks using your saved logins — lower cost than cloud web search.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  TextButton(
                    onPressed: () => _openChromeDownload(),
                    child: const Text('Get Chrome'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF052E16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _startSetupInChat(context),
                    child: const Text('Set up in chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChromeDownload() async {
    final uri = Uri.parse('https://www.google.com/chrome/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startSetupInChat(BuildContext context) async {
    await showDevicePromptSheet(context, promptStore, deviceName: deviceName);
    if (!context.mounted) return;
    await promptStore.promptSend(deviceChromeSetupPromptText(deviceName));
  }
}
