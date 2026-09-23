import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/widgets/billing/ui_quota_ring.dart';
import 'package:alienai_c35/widgets/ui/ui_speak_toggle.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _menuBg = Color(0xFF18181B);
const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _hoverBg = Color(0xFF27272A);
const _menuW = 320.0;
const _menuOverlap = 36.0;

class UiAccountMenuAction {
  const UiAccountMenuAction({
    this.conn,
    this.onSettings,
    this.onReferralTree,
    this.onBalance,
    this.onPackage,
    this.onCommissionTap,
    this.onFinancePayments,
    this.onFinanceReceiveAccounts,
    this.onLock,
    this.onSignOut,
    this.onBots,
    this.onDevices,
    this.onSites,
    this.onRootConsole,
    this.botsCount,
    this.devicesCount,
    this.sitesCount,
  });

  final ReferralConn? conn;
  final VoidCallback? onSettings;
  final VoidCallback? onReferralTree;
  final VoidCallback? onBalance;
  final VoidCallback? onPackage;
  final VoidCallback? onCommissionTap;
  final VoidCallback? onFinancePayments;
  final VoidCallback? onFinanceReceiveAccounts;
  final VoidCallback? onLock;
  final VoidCallback? onSignOut;
  final VoidCallback? onBots;
  final VoidCallback? onDevices;
  final VoidCallback? onSites;
  final VoidCallback? onRootConsole;
  final int? botsCount;
  final int? devicesCount;
  final int? sitesCount;
}

Future<void> uiAccountMenuShow(BuildContext anchorCtx, {UiAccountMenuAction? action}) async {
  final box = anchorCtx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return;
  final origin = box.localToGlobal(Offset.zero);
  final acts = action ?? const UiAccountMenuAction();
  await showDialog<void>(
    context: anchorCtx,
    barrierColor: Colors.black26,
    builder: (dctx) => _UiAccountMenuDialog(origin: origin, anchorSize: box.size, action: acts),
  );
}

class UiAccountBtn extends StatefulWidget {
  const UiAccountBtn({super.key, required this.tooltip, required this.onTap, required this.child});

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<UiAccountBtn> createState() => _UiAccountBtnState();
}

class _UiAccountBtnState extends State<UiAccountBtn> {
  var _hover = false;

  @override
  Widget build(BuildContext context) => uiTooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(
            color: _hover ? _hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(onTap: widget.onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(6), child: widget.child)),
          ),
        ),
      );
}

class _UiAccountMenuDialog extends StatefulWidget {
  const _UiAccountMenuDialog({required this.origin, required this.anchorSize, required this.action});

  final Offset origin;
  final Size anchorSize;
  final UiAccountMenuAction action;

  @override
  State<_UiAccountMenuDialog> createState() => _UiAccountMenuDialogState();
}

class _UiAccountMenuDialogState extends State<_UiAccountMenuDialog> {
  void _popThen(VoidCallback? fn) {
    Navigator.pop(context);
    fn?.call();
  }

  String _accountName() {
    final name = Session.instance.name.trim();
    return name.isNotEmpty ? name : 'Account';
  }

  List<String> _accountBadgeLabels(Session s) => [
        if (s.isRoot) referralGlobalRoleLabel('root'),
        ...s.globalRoles.where((role) => role != 'root').map(referralGlobalRoleLabel),
      ];

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final left = (widget.origin.dx + widget.anchorSize.width - _menuW).clamp(8.0, screen.width - _menuW - 8);
    final top = (widget.origin.dy + widget.anchorSize.height - _menuOverlap).clamp(8.0, screen.height - 380);
    final s = Session.instance;
    final acts = widget.action;
    final badgeLabels = _accountBadgeLabels(s);
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: _menuW,
          child: Material(
            color: _menuBg,
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
            child: ListenableBuilder(
              listenable: AppStore.instance,
              builder: (context, _) {
                final billing = AppStore.instance.billing;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _popThen(acts.onSettings),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            UiUserAvatar(name: s.name, email: s.email, handle: s.handle, pic: s.pic, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_accountName(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(profileAlienAddress(s.handle), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                                  if (badgeLabels.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: badgeLabels.map((label) {
                                        final isRoot = label == referralGlobalRoleLabel('root');
                                        return _AccountRoleBadge(
                                          label: label,
                                          onTap: isRoot ? acts.onRootConsole == null ? null : () => _popThen(acts.onRootConsole) : null,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (acts.onSettings != null) const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
                          ],
                        ),
                      ),
                    ),
                    if (billing != null) ...[
                      const Divider(height: 1, color: _border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: uiQuotaPackagePanelFromAccount(
                          billing,
                          onBalanceTap: acts.onBalance == null ? null : () => _popThen(acts.onBalance),
                          onPackageTap: acts.onPackage == null ? null : () => _popThen(acts.onPackage),
                        ),
                      ),
                      if (referralCommissionHasBalance(billing.commissionAvailableUsd, billing.commissionAvailableIdr) && acts.onCommissionTap != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Material(
                            color: _hoverBg,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => _popThen(acts.onCommissionTap),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF60A5FA)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Commission', style: TextStyle(color: _muted, fontSize: 11)),
                                          Text(
                                            referralCommissionStripLabel(billing.commissionAvailableUsd, billing.commissionAvailableIdr),
                                            style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (acts.onFinancePayments != null || acts.onFinanceReceiveAccounts != null) ...[
                      const Divider(height: 1, color: _border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          children: [
                            if (acts.onFinancePayments != null)
                              _FinanceNavBtn(icon: Icons.payments_outlined, label: 'Finance payments', onTap: () => _popThen(acts.onFinancePayments)),
                            if (acts.onFinanceReceiveAccounts != null) ...[
                              if (acts.onFinancePayments != null) const SizedBox(height: 6),
                              _FinanceNavBtn(icon: Icons.account_balance_outlined, label: 'Receive accounts', onTap: () => _popThen(acts.onFinanceReceiveAccounts)),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (_hasNavCounts(acts)) ...[
                      const Divider(height: 1, color: _border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          children: [
                            if (acts.onBots != null) Expanded(child: _NavCountBtn(icon: Icons.smart_toy_outlined, count: acts.botsCount ?? 0, label: 'Bots', onTap: () => _popThen(acts.onBots))),
                            if (acts.onDevices != null) ...[const SizedBox(width: 6), Expanded(child: _NavCountBtn(icon: Icons.devices_outlined, count: acts.devicesCount ?? 0, label: 'Devices', onTap: () => _popThen(acts.onDevices)))],
                            if (acts.onSites != null) ...[const SizedBox(width: 6), Expanded(child: _NavCountBtn(icon: Icons.language_outlined, count: acts.sitesCount ?? 0, label: 'Sites', onTap: () => _popThen(acts.onSites)))],
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1, color: _border),
                    ListenableBuilder(
                      listenable: VoicePrefs.instance,
                      builder: (context, _) => UiSpeakToggleRow(
                        enabled: VoicePrefs.instance.speakEnabled,
                        onChanged: (v) => VoicePrefs.instance.setSpeakEnabled(v),
                      ),
                    ),
                    if (acts.onReferralTree != null || acts.onLock != null || acts.onSignOut != null) ...[
                      const Divider(height: 1, color: _border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
                          children: [
                            const Spacer(),
                            if (acts.onReferralTree != null) ...[
                              _MenuIconBtn(icon: Icons.account_tree_outlined, tooltip: 'Referral tree', onTap: () => _popThen(acts.onReferralTree)),
                              const SizedBox(width: 8),
                            ],
                            if (acts.onLock != null) ...[
                              _MenuIconBtn(icon: Icons.lock_outline_rounded, tooltip: 'Lock', onTap: () => _popThen(acts.onLock)),
                              const SizedBox(width: 8),
                            ],
                            if (acts.onSignOut != null) _MenuIconBtn(icon: Icons.logout_rounded, tooltip: 'Sign out', destructive: true, onTap: () => _popThen(acts.onSignOut)),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _hasNavCounts(UiAccountMenuAction acts) => acts.onBots != null || acts.onDevices != null || acts.onSites != null;
}

class _AccountRoleBadge extends StatelessWidget {
  const _AccountRoleBadge({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _hoverBg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 10, fontWeight: FontWeight.w600)),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: child);
  }
}

class _NavCountBtn extends StatelessWidget {
  const _NavCountBtn({required this.icon, required this.count, required this.label, this.onTap});

  final IconData icon;
  final int count;
  final String label;
  final VoidCallback? onTap;

  static const _textStyle = TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) => Material(
        color: _hoverBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFFA1A1AA)),
                const SizedBox(width: 5),
                Flexible(child: Text('$count $label', maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle)),
              ],
            ),
          ),
        ),
      );
}

class _MenuIconBtn extends StatelessWidget {
  const _MenuIconBtn({required this.icon, required this.tooltip, this.destructive = false, this.onTap});

  final IconData icon;
  final String tooltip;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFF87171) : const Color(0xFFA1A1AA);
    return uiTooltip(
      message: tooltip,
      child: Material(
        color: _hoverBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 18, color: color))),
      ),
    );
  }
}

class _FinanceNavBtn extends StatelessWidget {
  const _FinanceNavBtn({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _hoverBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFA1A1AA)),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w500))),
                const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
              ],
            ),
          ),
        ),
      );
}
