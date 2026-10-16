import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/mail/mail_inbox_bus.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alienai_c35/widgets/ui/ui_account_role_badges.dart';
import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/widgets/ai/ui_live_call_chip.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/billing/billing_store_sync.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/billing/ui_quota_ring.dart';
import 'package:alienai_c35/widgets/ui/ui_account_assets_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_speak_toggle.dart';
import 'package:alienai_c35/widgets/ui/ui_app_bar_chip.dart';
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
    this.onTasks,
    this.onBalance,
    this.onPackage,
    this.onCommissionTap,
    this.onFinancePayments,
    this.onFinanceReceiveAccounts,
    this.onMarketingGenerateVoucher,
    this.onLock,
    this.onSignOut,
    this.onBots,
    this.onDevices,
    this.onSites,
    this.onRootConsole,
    this.onDirectorManageSite,
    this.onMail,
    this.onNotifications,
    this.composerModel,
    this.liveOffers = const [],
    this.onLiveCallStart,
    this.shellStore,
    this.botsCount,
    this.devicesCount,
    this.sitesCount,
    this.mailInboxCount,
    this.notifyUnreadCount,
  });

  final ReferralConn? conn;
  final VoidCallback? onSettings;
  final VoidCallback? onReferralTree;
  final VoidCallback? onTasks;
  final VoidCallback? onBalance;
  final VoidCallback? onPackage;
  final VoidCallback? onCommissionTap;
  final VoidCallback? onFinancePayments;
  final VoidCallback? onFinanceReceiveAccounts;
  final VoidCallback? onMarketingGenerateVoucher;
  final VoidCallback? onLock;
  final VoidCallback? onSignOut;
  final VoidCallback? onBots;
  final VoidCallback? onDevices;
  final VoidCallback? onSites;
  final VoidCallback? onRootConsole;
  final VoidCallback? onDirectorManageSite;
  final VoidCallback? onMail;
  final VoidCallback? onNotifications;
  final AgentModel? composerModel;
  final List<LiveOffer> liveOffers;
  final ValueChanged<LiveOffer>? onLiveCallStart;
  final ChatStore? shellStore;
  final int? botsCount;
  final int? devicesCount;
  final int? sitesCount;
  final int? mailInboxCount;
  final int? notifyUnreadCount;
}

Future<void> uiAccountMenuShow(BuildContext anchorCtx, {UiAccountMenuAction? action}) async {
  final box = anchorCtx.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return;
  final origin = box.localToGlobal(Offset.zero);
  final acts = action ?? const UiAccountMenuAction();
  await showDialog<void>(
    context: anchorCtx,
    barrierColor: Colors.black26,
    builder: (dctx) => uiSemanticsGuard(_UiAccountMenuDialog(origin: origin, anchorSize: box.size, action: acts)),
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
  @override
  Widget build(BuildContext context) => uiTooltip(
        message: widget.tooltip,
        child: UiAppBarChip(onTap: widget.onTap, child: widget.child),
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
  var _billingHydrating = false;

  bool _billingPlanTrustedPaid(BillingAccount? billing) =>
      billing != null && billingAccountPaidEntitlement(billing);

  @override
  void initState() {
    super.initState();
    final conn = widget.action.conn;
    _billingHydrating = conn != null && AppStore.instance.billing == null;
    unawaited(_billingEnsure());
  }

  Future<void> _billingEnsure() async {
    final conn = widget.action.conn;
    if (conn == null) {
      if (mounted && _billingHydrating) setState(() => _billingHydrating = false);
      return;
    }
    final trustedPaid = _billingPlanTrustedPaid(AppStore.instance.billing);
    try {
      if (trustedPaid) {
        unawaited(billingStoreRefresh(conn));
      } else {
        await billingStoreRefresh(conn);
      }
    } catch (_) {}
    if (mounted && _billingHydrating) setState(() => _billingHydrating = false);
  }

  void _popThen(VoidCallback? fn) {
    Navigator.pop(context);
    fn?.call();
  }

  void _openAssets(UiAccountMenuAction acts) {
    final store = acts.shellStore;
    final nav = store?.navCounts;
    final mailUnread = acts.mailInboxCount ?? mailInboxBus.inboxCount;
    final notifyUnread = store?.notifyUnreadCount ?? acts.notifyUnreadCount ?? 0;
    unawaited(
      uiAccountAssetsDialogShow(
        context,
        action: UiAccountAssetsAction(
          onBots: acts.onBots == null ? null : () => _popThen(acts.onBots),
          onDevices: acts.onDevices == null ? null : () => _popThen(acts.onDevices),
          onSites: acts.onSites == null ? null : () => _popThen(acts.onSites),
          onMail: acts.onMail == null ? null : () => _popThen(acts.onMail),
          onNotifications: acts.onNotifications == null ? null : () => _popThen(acts.onNotifications),
          botsCount: acts.botsCount ?? nav?.bots ?? 0,
          devicesCount: acts.devicesCount ?? nav?.devices ?? 0,
          sitesCount: acts.sitesCount ?? nav?.sites ?? 0,
          mailboxCount: nav?.mailboxCount ?? 0,
          mailInboxUnread: mailUnread,
          notifyUnread: notifyUnread,
        ),
      ),
    );
  }

  int _assetsBadgeCount(UiAccountMenuAction acts) {
    final mailUnread = acts.mailInboxCount ?? mailInboxBus.inboxCount;
    final notifyUnread = acts.shellStore?.notifyUnreadCount ?? acts.notifyUnreadCount ?? 0;
    return mailUnread + notifyUnread;
  }

  bool _hasAssetsEntry(UiAccountMenuAction acts) =>
      acts.onBots != null ||
      acts.onDevices != null ||
      acts.onSites != null ||
      acts.onMail != null ||
      acts.onNotifications != null;

  Future<void> _onLiveCallPick(LiveOffer offer) async {
    if (!offer.enabled) return;
    await VoicePrefs.instance.setTalkEnabled(false);
    if (!mounted) return;
    Navigator.pop(context);
    widget.action.onLiveCallStart?.call(offer);
  }

  String _accountName() {
    final name = Session.instance.name.trim();
    return name.isNotEmpty ? name : 'Account';
  }

  UiAccountRoleBadgesAction _badgeAction(UiAccountMenuAction acts) => UiAccountRoleBadgesAction(
        onRootConsole: acts.onRootConsole == null ? null : () => _popThen(acts.onRootConsole),
        onDirectorManageSite: acts.onDirectorManageSite == null ? null : () => _popThen(acts.onDirectorManageSite),
        onFinancePayments: acts.onFinancePayments == null ? null : () => _popThen(acts.onFinancePayments),
        onFinanceReceiveAccounts: acts.onFinanceReceiveAccounts == null ? null : () => _popThen(acts.onFinanceReceiveAccounts),
        onMarketingGenerateVoucher:
            acts.onMarketingGenerateVoucher == null ? null : () => _popThen(acts.onMarketingGenerateVoucher),
      );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final left = (widget.origin.dx + widget.anchorSize.width - _menuW).clamp(8.0, screen.width - _menuW - 8);
    final top = (widget.origin.dy + widget.anchorSize.height - _menuOverlap).clamp(8.0, screen.height - 380);
    final s = Session.instance;
    final acts = widget.action;
    final badgeAction = _badgeAction(acts);
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
              listenable: Listenable.merge([
                AppStore.instance,
                mailInboxBus,
                if (acts.shellStore != null) acts.shellStore!,
              ]),
              builder: (context, _) {
                final billing = AppStore.instance.billing;
                final showBillingPanel = billing != null;
                final planTierLoading = _billingHydrating && !showBillingPanel;
                final billingRow = billing;
                final assetsBadge = _assetsBadgeCount(acts);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: acts.onSettings == null ? null : () => _popThen(acts.onSettings),
                              borderRadius: BorderRadius.circular(8),
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
                                        Text(
                                          profileIdentityLabel(handle: s.handle, email: s.email),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: _muted, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        UiAccountRoleBadges(action: badgeAction),
                                      ],
                                    ),
                                  ),
                                  if (acts.onSettings != null) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_hasAssetsEntry(acts)) ...[
                            const SizedBox(width: 6),
                            _AssetsHeaderBtn(badge: assetsBadge, onTap: () => _openAssets(acts)),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: showBillingPanel && billingRow != null
                          ? uiQuotaPackagePanelFromAccount(
                              billingRow,
                              quota: AppStore.instance.quota,
                              planTierLoading: planTierLoading,
                              onBalanceTap: acts.onBalance == null ? null : () => _popThen(acts.onBalance),
                              onPackageTap: acts.onPackage == null ? null : () => _popThen(acts.onPackage),
                            )
                          : uiQuotaPackagePanelLimitPlaceholder(
                              planTierLoading: _billingHydrating,
                              onPackageTap: acts.onPackage == null ? null : () => _popThen(acts.onPackage),
                            ),
                    ),
                    if (billing != null && referralCommissionHasBalance(billing.commissionAvailableUsd, billing.commissionAvailableIdr) && acts.onCommissionTap != null) ...[
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
                    if (_hasNavSection(acts)) ...[
                      const Divider(height: 1, color: _border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_hasTalkCallRow(acts))
                              ListenableBuilder(
                                listenable: Listenable.merge([VoicePrefs.instance, catalogTranslationTick]),
                                builder: (context, _) {
                                  final model = acts.composerModel;
                                  final callChip = acts.onLiveCallStart == null || model == null
                                      ? null
                                      : UiLiveCallChip(
                                          composerModel: model,
                                          offers: acts.liveOffers,
                                          expand: true,
                                          dense: true,
                                          onStart: _onLiveCallPick,
                                        );
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: UiAccountTalkModeMenu(
                                          talkEnabled: VoicePrefs.instance.talkEnabled,
                                          onSelectTalkEnabled: (enabled) async {
                                            await VoicePrefs.instance.setTalkEnabled(enabled);
                                          },
                                        ),
                                      ),
                                      if (callChip != null) ...[
                                        const SizedBox(width: 6),
                                        Expanded(child: callChip),
                                      ],
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1, color: _border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (acts.onTasks != null)
                            _MenuIconBtn(
                              icon: Icons.task_alt_rounded,
                              tooltip: 'account.tasks'.tr(),
                              onTap: () => _popThen(acts.onTasks),
                            ),
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _hasTalkCallRow(UiAccountMenuAction acts) => true;

  bool _hasNavSection(UiAccountMenuAction acts) => _hasTalkCallRow(acts);
}

class _AssetsHeaderBtn extends StatelessWidget {
  const _AssetsHeaderBtn({required this.badge, required this.onTap});

  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = badge <= 0 ? '' : (badge > 99 ? '99+' : '$badge');
    return uiTooltip(
      message: 'account.assetsTooltip'.tr(),
      child: Material(
        color: _hoverBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.fromLTRB(badgeLabel.isEmpty ? 7 : 8, 0, 7, 0),
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (badgeLabel.isNotEmpty) ...[
                    Text(badgeLabel, style: const TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w700, height: 1)),
                    const SizedBox(width: 4),
                  ],
                  const Icon(Icons.widgets_outlined, size: 18, color: Color(0xFFA1A1AA)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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

