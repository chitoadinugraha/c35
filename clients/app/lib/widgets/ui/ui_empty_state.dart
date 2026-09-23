import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFA1A1AA);
const _title = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiEmptyState extends StatelessWidget {
  const UiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionHint,
    this.actionIcon = Icons.add_circle_outline,
  });

  factory UiEmptyState.devices() => const UiEmptyState(
        icon: Icons.devices_outlined,
        title: 'No devices yet',
        subtitle: 'Pair a remote PC, phone, or IoT device to control it from here.',
        actionHint: 'Tap + to add',
      );

  factory UiEmptyState.sites() => const UiEmptyState(
        icon: Icons.language_outlined,
        title: 'No sites yet',
        subtitle: 'Create a site identity to publish on alienai.id.',
      );

  factory UiEmptyState.bots() => const UiEmptyState(
        icon: Icons.smart_toy_outlined,
        title: 'No bots yet',
        subtitle: 'Create a chat bot and connect Telegram or WhatsApp.',
        actionHint: 'Tap + in the sidebar',
        actionIcon: Icons.add,
      );

  factory UiEmptyState.noMatches(String noun) => UiEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching $noun',
        subtitle: 'Try a different search term.',
      );

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionHint;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Icon(icon, size: 28, color: _muted),
                ),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _title, fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: _text, fontSize: 13, height: 1.45)),
                ],
                if (actionHint != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionIcon != null) ...[Icon(actionIcon, size: 16, color: _accent), const SizedBox(width: 6)],
                      Text(actionHint!, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
