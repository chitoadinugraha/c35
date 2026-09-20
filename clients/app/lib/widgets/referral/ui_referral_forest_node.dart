import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

class UiReferralForestNode extends StatelessWidget {
  const UiReferralForestNode({
    super.key,
    required this.node,
    this.isSelf = false,
    this.canExpand = false,
    this.expanding = false,
    this.remaining = 0,
    this.onTap,
    this.onExpand,
  });

  final ReferralTreeNode node;
  final bool isSelf;
  final bool canExpand;
  final bool expanding;
  final int remaining;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;

  static const _accent = Color(0xFF34D399);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);

  @override
  Widget build(BuildContext context) {
    final handle = node.displayHandle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UiUserAvatar(name: node.name, handle: node.handle, pic: node.avatarUrl, size: 32, showBorder: false),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isSelf) const Text(' (you)', style: TextStyle(color: _muted, fontSize: 11)),
                      ],
                    ),
                    if (handle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(handle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                    ],
                    if (node.childCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${node.childCount} referral${node.childCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: _accent, fontSize: 11),
                      ),
                    ],
                    if (referralNodeIsRoot(node) || node.globalRoles.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (referralNodeIsRoot(node)) const _RoleBadge(label: 'Root'),
                          ...node.globalRoles.where((role) => role != 'root').map((role) => _RoleBadge(label: referralGlobalRoleLabel(role))),
                        ],
                      ),
                    ],
                    if (canExpand)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: expanding ? null : onExpand,
                            icon: Icon(expanding ? Icons.hourglass_top : Icons.expand_more, size: 16),
                            label: Text(expanding ? 'Loading…' : remaining > 0 ? 'Expand $remaining' : 'Expand'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: _accent,
                              backgroundColor: _accent.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
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
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class UiReferralForestExpand extends StatelessWidget {
  const UiReferralForestExpand({super.key, required this.remaining, this.expanding = false, this.onExpand});

  final int remaining;
  final bool expanding;
  final VoidCallback? onExpand;

  static const _fill = Color(0xFF18181B);
  static const _border = Color(0xFF3F3F46);
  static const _muted = Color(0xFFA1A1AA);
  static const _icon = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    final label = expanding ? 'Loading…' : remaining > 0 ? 'Expand $remaining' : 'Expand';
    return Material(
      color: _fill,
      elevation: 0,
      shape: const StadiumBorder(side: BorderSide(color: _border, width: 1.5)),
      child: InkWell(
        onTap: expanding ? null : onExpand,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (expanding)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
              else
                const Icon(Icons.account_tree_outlined, size: 15, color: _icon),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: expanding ? _icon : _muted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
