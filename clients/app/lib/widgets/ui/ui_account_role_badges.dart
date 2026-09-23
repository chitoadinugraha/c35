import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter/material.dart';

const _badgeBg = Color(0xFF27272A);
const _badgeText = Color(0xFFE4E4E7);
const _muted = Color(0xFF71717A);

enum UiAccountRoleBadgeSize { menu, page }

class UiAccountRoleBadgesAction {
  const UiAccountRoleBadgesAction({this.onRootConsole, this.onFinancePayments, this.onFinanceReceiveAccounts});

  final VoidCallback? onRootConsole;
  final VoidCallback? onFinancePayments;
  final VoidCallback? onFinanceReceiveAccounts;
}

bool uiAccountRoleHasFinanceNav(UiAccountRoleBadgesAction action) => action.onFinancePayments != null || action.onFinanceReceiveAccounts != null;

List<String> uiAccountRoleBadgeLabels(Session s, UiAccountRoleBadgesAction action) => [
      if (s.isRoot) referralGlobalRoleLabel('root'),
      ...s.globalRoles.where((role) {
        if (role == 'root') return false;
        if (uiAccountRoleHasFinanceNav(action) && role == 'finance') return false;
        return true;
      }).map(referralGlobalRoleLabel),
    ];

class UiAccountRoleBadges extends StatelessWidget {
  const UiAccountRoleBadges({super.key, required this.action, this.size = UiAccountRoleBadgeSize.menu});

  final UiAccountRoleBadgesAction action;
  final UiAccountRoleBadgeSize size;

  bool get _large => size == UiAccountRoleBadgeSize.page;

  double get _fontSize => _large ? 12 : 10;

  EdgeInsets get _pad => _large ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  @override
  Widget build(BuildContext context) {
    final s = Session.instance;
    final labels = uiAccountRoleBadgeLabels(s, action);
    final hasFinanceNav = uiAccountRoleHasFinanceNav(action);
    if (labels.isEmpty && !hasFinanceNav) return const SizedBox.shrink();
    return Wrap(
      spacing: _large ? 6 : 4,
      runSpacing: _large ? 6 : 4,
      children: [
        ...labels.map((label) {
          final isRoot = label == referralGlobalRoleLabel('root');
          return _RoleBadge(
            label: label,
            fontSize: _fontSize,
            padding: _pad,
            onTap: isRoot ? action.onRootConsole : null,
          );
        }),
        if (hasFinanceNav) _FinanceBadge(action: action, fontSize: _fontSize, padding: _pad),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.fontSize, required this.padding, this.onTap});

  final String label;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: padding,
      decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: _badgeText, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: child);
  }
}

class _FinanceBadge extends StatelessWidget {
  const _FinanceBadge({required this.action, required this.fontSize, required this.padding});

  final UiAccountRoleBadgesAction action;
  final double fontSize;
  final EdgeInsets padding;

  Future<void> _openMenu(BuildContext anchorCtx) async {
    final box = anchorCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: anchorCtx,
      color: const Color(0xFF18181B),
      position: RelativeRect.fromLTRB(origin.dx, origin.dy + box.size.height + 4, origin.dx, origin.dy),
      items: [
        if (action.onFinancePayments != null)
          const PopupMenuItem(
            value: 'payments',
            child: Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: _muted),
                SizedBox(width: 10),
                Text('Payments', style: TextStyle(color: _badgeText, fontSize: 13)),
              ],
            ),
          ),
        if (action.onFinanceReceiveAccounts != null)
          const PopupMenuItem(
            value: 'receive',
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 16, color: _muted),
                SizedBox(width: 10),
                Text('Receive accounts', style: TextStyle(color: _badgeText, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
    switch (selected) {
      case 'payments':
        action.onFinancePayments?.call();
      case 'receive':
        action.onFinanceReceiveAccounts?.call();
    }
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (anchorCtx) => InkWell(
          onTap: () => _openMenu(anchorCtx),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(referralGlobalRoleLabel('finance'), style: TextStyle(color: _badgeText, fontSize: fontSize, fontWeight: FontWeight.w600)),
                Icon(Icons.expand_more_rounded, size: fontSize + 2, color: _muted),
              ],
            ),
          ),
        ),
      );
}
