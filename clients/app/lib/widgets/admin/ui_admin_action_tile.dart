import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminActionTile extends StatelessWidget {
  const UiAdminActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return Material(
      color: primary ? adminAccent : adminPanel,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: primary ? null : Border.all(color: adminBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: primary ? adminAccentFg : adminText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: primary ? adminAccentFg : adminText, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: primary ? adminAccentFg.withValues(alpha: 0.75) : adminMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() => Material(
        color: adminPanel,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary ? adminAccent.withValues(alpha: 0.55) : adminBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (primary)
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: adminAccent, borderRadius: BorderRadius.circular(2)),
                  ),
                Icon(icon, size: 17, color: primary ? adminAccent : adminText),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: adminMuted.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      );
}
