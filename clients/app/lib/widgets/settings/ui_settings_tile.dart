import 'package:flutter/material.dart';

class UiSettingsTile extends StatelessWidget {
  const UiSettingsTile({super.key, this.icon, this.leading, required this.title, this.subtitle, this.onTap})
      : assert(icon != null || leading != null);

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              leading ?? Icon(icon, color: const Color(0xFF71717A), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  ],
                ]),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Color(0xFF52525B), size: 20),
            ]),
          ),
        ),
      );
}

Widget uiSettingsDivider() => const Divider(height: 1, color: Color(0xFF27272A), indent: 16, endIndent: 16);
