import 'package:alienai_c35/c/mail/mail_inbox_bus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _panel = Color(0xFF27272A);
const _border = Color(0xFF3F3F46);

class UiAccountAssetsAction {
  const UiAccountAssetsAction({
    this.onBots,
    this.onDevices,
    this.onSites,
    this.onMail,
    this.onNotifications,
    this.botsCount = 0,
    this.devicesCount = 0,
    this.sitesCount = 0,
    this.mailboxCount = 0,
    this.mailInboxUnread = 0,
    this.notifyUnread = 0,
  });

  final VoidCallback? onBots;
  final VoidCallback? onDevices;
  final VoidCallback? onSites;
  final VoidCallback? onMail;
  final VoidCallback? onNotifications;
  final int botsCount;
  final int devicesCount;
  final int sitesCount;
  final int mailboxCount;
  final int mailInboxUnread;
  final int notifyUnread;

  bool get hasAny =>
      onBots != null || onDevices != null || onSites != null || onMail != null || onNotifications != null;
}

Future<void> uiAccountAssetsDialogShow(BuildContext context, {required UiAccountAssetsAction action}) async {
  if (!action.hasAny) return;
  await uiDialogShow<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => UiDialog(
      maxWidth: 360,
      padding: EdgeInsets.zero,
      inset: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C21), Color(0xFF141417)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AssetsDialogHeader(onClose: () => Navigator.pop(ctx)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (action.onBots != null || action.onDevices != null || action.onSites != null) ...[
                      Text(
                        'account.sectionWorkspace'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (action.onBots != null)
                            Expanded(
                              child: _WorkspaceStatTile(
                                icon: Icons.smart_toy_rounded,
                                accent: const Color(0xFF60A5FA),
                                count: action.botsCount,
                                label: 'account.bots'.tr(),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  action.onBots?.call();
                                },
                              ),
                            ),
                          if (action.onDevices != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _WorkspaceStatTile(
                                icon: Icons.devices_rounded,
                                accent: const Color(0xFFA78BFA),
                                count: action.devicesCount,
                                label: 'account.devices'.tr(),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  action.onDevices?.call();
                                },
                              ),
                            ),
                          ],
                          if (action.onSites != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _WorkspaceStatTile(
                                icon: Icons.language_rounded,
                                accent: const Color(0xFF34D399),
                                count: action.sitesCount,
                                label: 'account.sites'.tr(),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  action.onSites?.call();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (action.onMail != null || action.onNotifications != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'account.sectionInbox'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (action.onMail != null)
                        _InboxAssetRow(
                          icon: Icons.mark_email_unread_rounded,
                          accent: const Color(0xFFFBBF24),
                          title: action.mailboxCount > 0
                              ? 'account.mailboxesCount'.tr(namedArgs: {'count': '${action.mailboxCount}'})
                              : 'mail.title'.tr(),
                          subtitle: action.mailInboxUnread > 0
                              ? 'account.mailNew'.tr(namedArgs: {'count': '${action.mailInboxUnread}'})
                              : 'account.mailNoNew'.tr(),
                          showPulse: action.mailInboxUnread > 0,
                          badge: action.mailInboxUnread > 0 ? MailInboxBus.unreadMenuLabel(action.mailInboxUnread) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            action.onMail?.call();
                          },
                        ),
                      if (action.onNotifications != null) ...[
                        if (action.onMail != null) const SizedBox(height: 8),
                        _InboxAssetRow(
                          icon: Icons.notifications_active_rounded,
                          accent: const Color(0xFF22D3EE),
                          title: 'account.notifications'.tr(),
                          subtitle: action.notifyUnread > 0
                              ? 'account.notificationsUnread'.tr(namedArgs: {'count': '${action.notifyUnread}'})
                              : 'account.notificationsNone'.tr(),
                          showPulse: action.notifyUnread > 0,
                          badge: action.notifyUnread > 0 ? (action.notifyUnread > 99 ? '99+' : '${action.notifyUnread}') : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            action.onNotifications?.call();
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AssetsDialogHeader extends StatelessWidget {
  const _AssetsDialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
          color: Color(0xFF1A2330),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E7490), Color(0xFF2563EB)],
                ),
                boxShadow: const [BoxShadow(color: Color(0x4022D3EE), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.widgets_rounded, size: 22, color: Color(0xFFF8FAFC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('account.assets'.tr(), style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 2),
                  Text('account.assetsSubtitle'.tr(), style: const TextStyle(color: _muted, fontSize: 11, height: 1.25)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20, color: _muted),
            ),
          ],
        ),
      );
}

class _WorkspaceStatTile extends StatelessWidget {
  const _WorkspaceStatTile({
    required this.icon,
    required this.accent,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(height: 10),
                Text(
                  '$count',
                  style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700, height: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      );
}

class _InboxAssetRow extends StatelessWidget {
  const _InboxAssetRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.showPulse = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool showPulse;

  @override
  Widget build(BuildContext context) => Material(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: showPulse ? accent.withValues(alpha: 0.35) : _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    if (showPulse)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: _panel, width: 1.5),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: showPulse ? accent : _muted, fontSize: 11, height: 1.2)),
                    ],
                  ),
                ),
                if (badge != null && badge!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(badge!, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, height: 1)),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _muted.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      );
}