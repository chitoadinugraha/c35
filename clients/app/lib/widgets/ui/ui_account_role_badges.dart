import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:flutter/material.dart';

const _badgeBg = Color(0xFF27272A);
const _badgeText = Color(0xFFE4E4E7);
const _muted = Color(0xFF71717A);

enum UiAccountRoleBadgeSize { menu, page }

class UiAccountRoleBadgesAction {
  const UiAccountRoleBadgesAction({
    this.onRootConsole,
    this.onFinancePayments,
    this.onFinanceReceiveAccounts,
    this.onMarketingGenerateVoucher,
  });

  final VoidCallback? onRootConsole;
  final VoidCallback? onFinancePayments;
  final VoidCallback? onFinanceReceiveAccounts;
  final VoidCallback? onMarketingGenerateVoucher;
}

bool uiAccountRoleHasFinanceNav(UiAccountRoleBadgesAction action) =>
    action.onFinancePayments != null || action.onFinanceReceiveAccounts != null;

bool uiAccountRoleHasMarketingNav(UiAccountRoleBadgesAction action) => action.onMarketingGenerateVoucher != null;

List<String> uiAccountRoleBadgeLabels(Session s, UiAccountRoleBadgesAction action) => [
      if (s.isRoot) referralGlobalRoleLabel('root'),
      ...s.globalRoles.where((role) {
        if (role == 'root') return false;
        if (uiAccountRoleHasFinanceNav(action) && (role == 'finance' || role == 'director')) return false;
        if (uiAccountRoleHasMarketingNav(action) && role == 'marketing') return false;
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
    final hasMarketingNav = uiAccountRoleHasMarketingNav(action);
    if (labels.isEmpty && !hasFinanceNav && !hasMarketingNav) return const SizedBox.shrink();
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
        if (hasMarketingNav) _MarketingBadge(action: action, fontSize: _fontSize, padding: _pad),
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

class _FinanceBadge extends StatefulWidget {
  const _FinanceBadge({required this.action, required this.fontSize, required this.padding});

  final UiAccountRoleBadgesAction action;
  final double fontSize;
  final EdgeInsets padding;

  @override
  State<_FinanceBadge> createState() => _FinanceBadgeState();
}

class _FinanceBadgeState extends State<_FinanceBadge> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu(BuildContext menuCtx) async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final selected = await showMenu<String>(
      context: menuCtx,
      color: const Color(0xFF18181B),
      position: uiMenuPositionBelow(menuCtx, box),
      items: [
        if (widget.action.onFinancePayments != null)
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
        if (widget.action.onFinanceReceiveAccounts != null)
          const PopupMenuItem(
            value: 'receive',
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 16, color: _muted),
                SizedBox(width: 10),
                Text('Payment accounts', style: TextStyle(color: _badgeText, fontSize: 13)),
              ],
            ),
          ),
        if (widget.action.onMarketingGenerateVoucher != null)
          const PopupMenuItem(
            value: 'voucher',
            child: Row(
              children: [
                Icon(Icons.card_giftcard_outlined, size: 16, color: _muted),
                SizedBox(width: 10),
                Text('Generate voucher', style: TextStyle(color: _badgeText, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
    switch (selected) {
      case 'payments':
        widget.action.onFinancePayments?.call();
      case 'receive':
        widget.action.onFinanceReceiveAccounts?.call();
      case 'voucher':
        widget.action.onMarketingGenerateVoucher?.call();
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          key: _anchorKey,
          padding: widget.padding,
          decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(referralGlobalRoleLabel('finance'), style: TextStyle(color: _badgeText, fontSize: widget.fontSize, fontWeight: FontWeight.w600)),
              Icon(Icons.expand_more_rounded, size: widget.fontSize + 2, color: _muted),
            ],
          ),
        ),
      );
}

class _MarketingBadge extends StatefulWidget {
  const _MarketingBadge({required this.action, required this.fontSize, required this.padding});

  final UiAccountRoleBadgesAction action;
  final double fontSize;
  final EdgeInsets padding;

  @override
  State<_MarketingBadge> createState() => _MarketingBadgeState();
}

class _MarketingBadgeState extends State<_MarketingBadge> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu(BuildContext menuCtx) async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final selected = await showMenu<String>(
      context: menuCtx,
      color: const Color(0xFF18181B),
      position: uiMenuPositionBelow(menuCtx, box),
      items: [
        if (widget.action.onMarketingGenerateVoucher != null)
          const PopupMenuItem(
            value: 'voucher',
            child: Row(
              children: [
                Icon(Icons.card_giftcard_outlined, size: 16, color: _muted),
                SizedBox(width: 10),
                Text('Generate voucher', style: TextStyle(color: _badgeText, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
    if (selected == 'voucher') widget.action.onMarketingGenerateVoucher?.call();
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          key: _anchorKey,
          padding: widget.padding,
          decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(referralGlobalRoleLabel('marketing'), style: TextStyle(color: _badgeText, fontSize: widget.fontSize, fontWeight: FontWeight.w600)),
              Icon(Icons.expand_more_rounded, size: widget.fontSize + 2, color: _muted),
            ],
          ),
        ),
      );
}
