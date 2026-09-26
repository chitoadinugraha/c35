import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/mail/mail_api.dart';
import 'package:alienai_c35/c/mail/mail_email_avatar.dart';
import 'package:alienai_c35/c/mail/mail_inbox_bus.dart';
import 'package:alienai_c35/c/mail/mail_models.dart';
import 'package:alienai_c35/c/mail/mail_open_bridge.dart';
import 'package:alienai_c35/c/mail/mail_staged_attachments.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/mail/ui_mail_email_avatar.dart';
import 'package:alienai_c35/widgets/ui/ui_fs_image.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_not_found.dart';
import 'package:alienai_c35/widgets/ui/ui_preview_page.dart';
import 'package:alienai_c35/widgets/ui/ui_site_catalog_layout.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
const _mailRailBreakpoint = 640;
const _mailMailingListMasterDetailBreakpoint = 640.0;
const _mailMasterDetailBreakpoint = 960;
const _mailMasterListWidth = 360.0;

String _formatMailWhenFull(int ms) {
  if (ms <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateFormat.yMMMMd().add_jm().format(dt);
}

bool _looksLikeEmail(String raw) {
  final s = raw.trim();
  return s.contains('@') && s.contains('.');
}

String _mailCssColor(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return 'rgb($r,$g,$b)';
}

List<String> _parseMailToAddresses(String raw) {
  return raw
      .split(RegExp(r'[,;\s]+'))
      .map((s) => s.trim())
      .where(_looksLikeEmail)
      .toList();
}

Document _buildMailReplyDocument(MailMessage message) {
  final from = message.fromAddr.trim();
  final rawBody = message.bodyText.trim();
  final body = rawBody.isNotEmpty
      ? rawBody
      : MailMessage.mailBodyPlain(message.bodyHtml);

  return Document(
    root: Node(
      type: 'page',
      children: [
        paragraphNode(),
        dividerNode(),
        paragraphNode(
          text: 'On ${_formatMailWhenFull(message.createdAt)}, $from wrote:',
        ),
        quoteNode(delta: Delta()..insert(body)),
      ],
    ),
  );
}

void _ensureEditorSelectionOnFocus(EditorState editorState, FocusNode focusNode) {
  focusNode.addListener(() {
    if (!focusNode.hasFocus || editorState.selection != null) return;
    final children = editorState.document.root.children;
    if (children.isEmpty) return;
    unawaited(
      editorState.updateSelectionWithReason(
        Selection.collapsed(Position(path: children.first.path, offset: 0)),
        reason: SelectionUpdateReason.uiEvent,
      ),
    );
  });
}

enum _MailFolder {
  contacts,
  mailingList,
  inbox,
  sent,
  draft,
  archive,
  spam,
}

extension _MailFolderExt on _MailFolder {
  String get label => switch (this) {
        _MailFolder.contacts => 'mail.contacts'.tr(),
        _MailFolder.mailingList => 'mail.mailingList'.tr(),
        _MailFolder.inbox => 'mail.inbox'.tr(),
        _MailFolder.sent => 'mail.sent'.tr(),
        _MailFolder.draft => 'mail.draft'.tr(),
        _MailFolder.archive => 'mail.archive'.tr(),
        _MailFolder.spam => 'mail.spam'.tr(),
      };

  IconData get icon => switch (this) {
        _MailFolder.contacts => Icons.contacts_outlined,
        _MailFolder.mailingList => Icons.mark_email_unread_outlined,
        _MailFolder.inbox => Icons.inbox_outlined,
        _MailFolder.sent => Icons.send_outlined,
        _MailFolder.draft => Icons.drafts_outlined,
        _MailFolder.archive => Icons.archive_outlined,
        _MailFolder.spam => Icons.report_outlined,
      };

  bool get isMessageFolder => switch (this) {
        _MailFolder.inbox ||
        _MailFolder.sent ||
        _MailFolder.draft ||
        _MailFolder.archive ||
        _MailFolder.spam =>
          true,
        _ => false,
      };
}

class EmailContact {
  const EmailContact({
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.source = 'recent',
  });

  final String name;
  final String email;
  final String avatarUrl;
  final String source; // 'app' or 'recent'

  String get displayName => name.trim().isNotEmpty ? name : email;
}

class PageMail extends StatefulWidget {
  const PageMail({
    super.key,
    required this.chatConn,
    this.initialMessageId,
    this.initialMailboxId,
  });

  final ChatConn chatConn;
  final int? initialMessageId;
  final int? initialMailboxId;

  @override
  State<PageMail> createState() => _PageMailState();
}

class _PageMailState extends State<PageMail> {
  late final MailApi _mailApi = MailApi(widget.chatConn);

  var _listRefreshing = false;
  var _loaded = false;
  String? _error;
  MailAccount? _account;
  List<MailMailbox> _mailboxes = [];
  int _selectedMailboxId = 0;
  final _emailAvatars = MailEmailAvatarResolver();

  int get _mailboxId {
    if (_selectedMailboxId > 0) return _selectedMailboxId;
    return _account?.mailboxId ?? 0;
  }

  MailMailbox? get _activeMailbox {
    final id = _mailboxId;
    if (id <= 0) return null;
    for (final m in _mailboxes) {
      if (m.mailboxId == id) return m;
    }
    return null;
  }

  String get _activeAddress =>
      _activeMailbox?.address ?? _account?.address ?? '';

  int get _subscriberLimit => _activeMailbox?.subscriberLimit ?? 1000;

  bool get _canWriteMailbox => _activeMailbox?.canWrite ?? false;

  Iterable<MailMailbox> get _writableMailboxes => _mailboxes.where((m) => m.canWrite);

  bool get _canCompose =>
      _loaded && (_writableMailboxes.isNotEmpty || (_account?.mailboxId ?? 0) > 0);

  MailMailbox? get _composeMailbox {
    final active = _activeMailbox;
    if (active != null && active.canWrite) return active;
    return _writableMailboxes.firstOrNull;
  }

  _MailFolder _currentFolder = _MailFolder.inbox;

  List<MailMessage> _inbox = [];
  List<MailMessage> _outbox = [];
  List<MailMessage> _archived = [];
  final List<MailMessage> _drafts = [];
  final List<MailMessage> _spam = [];

  List<MailingListGroup> _mailingLists = [];

  final Set<int> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  MailMessage? _activeMessage;
  int? _pendingNotifMessageId;
  int _pendingNotifMailboxId = 0;
  int _openMessageSeq = 0;
  bool _mailingListDrill = false;
  String? _mailingListDrillTitle;
  final _mailingListPaneKey = GlobalKey<_MailMailingListPaneState>();

  @override
  void initState() {
    super.initState();
    MailOpenBridge.instance.isMailMounted = () => mounted;
    MailOpenBridge.instance.onOpenMessage = _openMessageForNotification;
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
    
    _load();
  }

  @override
  void didUpdateWidget(PageMail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = widget.initialMessageId;
    final newMb = widget.initialMailboxId ?? 0;
    if (newId != null &&
        newId > 0 &&
        (newId != oldWidget.initialMessageId ||
            newMb != (oldWidget.initialMailboxId ?? 0))) {
      unawaited(_openMessageForNotification(newId, newMb));
    }
  }

  @override
  void dispose() {
    if (MailOpenBridge.instance.onOpenMessage == _openMessageForNotification) {
      MailOpenBridge.instance.onOpenMessage = null;
    }
    if (MailOpenBridge.instance.isMailMounted != null) {
      MailOpenBridge.instance.isMailMounted = null;
    }
    
    _searchCtrl.dispose();
    super.dispose();
  }

  ({List<MailMessage> inbox, List<MailMessage> outbox, List<MailMessage> archived})
      _partitionMailLists(List<MailMessage> rawInbox, List<MailMessage> rawOutbox) {
    final inbox = <MailMessage>[];
    final outbox = <MailMessage>[];
    final archived = <MailMessage>[];
    for (final m in rawInbox) {
      if (m.isArchived) {
        archived.add(m);
      } else {
        inbox.add(m);
      }
    }
    for (final m in rawOutbox) {
      if (m.isArchived) {
        archived.add(m);
      } else {
        outbox.add(m);
      }
    }
    return (inbox: inbox, outbox: outbox, archived: archived);
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted) return;
    final initialLoad = !refresh && !_loaded;
    setState(() {
      _listRefreshing = true;
      if (!refresh) _error = null;
    });
    final sw = Stopwatch()..start();
    try {
      final metaSw = Stopwatch()..start();
      final metaResults = await Future.wait<dynamic>([
        _mailApi.accountGet().then<MailAccount?>((a) => a).catchError((Object e, StackTrace st) {
          lError('$e\n$st');
          return null;
        }),
        _mailApi.mailboxList(),
      ]);
      final tMeta = metaSw.elapsedMilliseconds;
      final account = metaResults[0] as MailAccount?;
      final mailboxes = metaResults[1] as List<MailMailbox>;
      if (account == null && mailboxes.isEmpty) {
        throw StateError('mail.forbidden'.tr());
      }
      final selectedId = _selectedMailboxId > 0 &&
              mailboxes.any((m) => m.mailboxId == _selectedMailboxId)
          ? _selectedMailboxId
          : (account?.mailboxId != null && account!.mailboxId > 0
              ? account.mailboxId
              : mailboxes.firstOrNull?.mailboxId ?? 0);

      final inboxSw = Stopwatch()..start();
      final rawInbox = await _mailApi.list(direction: MailDirection.inbound, mailboxId: selectedId);
      final tInbox = inboxSw.elapsedMilliseconds;
      final inboxOnly = _partitionMailLists(rawInbox, const []);

      if (!mounted) return;
      setState(() {
        _account = account;
        _mailboxes = mailboxes;
        _selectedMailboxId = selectedId;
        _inbox = inboxOnly.inbox;
        _archived = inboxOnly.archived;
        _error = null;
        _loaded = true;
        if (initialLoad) _listRefreshing = false;
      });
      _syncEmailAvatarResolver();
      mailInboxBus.setMailboxAccess(mailboxes.isNotEmpty);
      mailInboxBus.setCount(_unreadInboxCount());

      final restSw = Stopwatch()..start();
      final restResults = await Future.wait<dynamic>([
        _mailApi.list(direction: MailDirection.outbound, mailboxId: selectedId),
        _mailApi.groupList(mailboxId: selectedId),
      ]);
      final tRest = restSw.elapsedMilliseconds;
      final rawOutbox = restResults[0] as List<MailMessage>;
      final serverGroups = restResults[1] as List<MailingListGroup>;
      final partitioned = _partitionMailLists(rawInbox, rawOutbox);

      l(
        '[Mail] load ${sw.elapsedMilliseconds}ms ΓÇö '
        'meta(account+mailboxes parallel):${tMeta}ms '
        'inbox:$tInbox ms '
        'rest(outbox+groups parallel):$tRest ms',
      );

      if (!mounted) return;
      _syncEmailAvatarResolver();
      setState(() {
        _inbox = partitioned.inbox;
        _outbox = partitioned.outbox;
        _archived = partitioned.archived;
        _mailingLists = serverGroups;
        _listRefreshing = false;
      });
      mailInboxBus.setMailboxAccess(mailboxes.isNotEmpty);
      mailInboxBus.setCount(_unreadInboxCount());
      final initialId = widget.initialMessageId;
      final initialMb = widget.initialMailboxId ?? 0;
      if (initialId != null && initialId > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openMessageForNotification(initialId, initialMb));
        });
      } else if (_pendingNotifMessageId != null && _pendingNotifMessageId! > 0) {
        final id = _pendingNotifMessageId!;
        final mb = _pendingNotifMailboxId;
        _pendingNotifMessageId = null;
        _pendingNotifMailboxId = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openMessageForNotification(id, mb));
        });
      }
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      setState(() {
        if (!_loaded) _error = uiFriendlyError(e);
        _listRefreshing = false;
        _loaded = true;
      });
    }
  }

  void _syncEmailAvatarResolver() {
    _emailAvatars.clear();
    for (final c in _buildContactList()) {
      if (c.avatarUrl.trim().isNotEmpty) {
        _emailAvatars.register(c.email, c.avatarUrl);
      }
    }
  }

  List<EmailContact> _buildContactList() {
    final Map<String, EmailContact> map = {};

    try {
      final cachedHome = null;
      if (cachedHome != null) {
        for (final c in cachedHome.contacts) {
          var addr = c.id.trim();
          if (addr.isNotEmpty) {
            if (!addr.contains('@')) {
              addr = '$addr@alienai.id';
            }
            map[addr.toLowerCase()] = EmailContact(
              name: c.name,
              email: addr,
              avatarUrl: c.avatarUrl,
              source: 'app',
            );
          }
        }
      }
    } catch (_) {}

    final allMessages = [..._inbox, ..._outbox, ..._archived];
    final myAddr = _activeAddress.toLowerCase();

    for (final m in allMessages) {
      final from = m.fromAddr.trim();
      if (from.isNotEmpty && from.toLowerCase() != myAddr) {
        map.putIfAbsent(
          from.toLowerCase(),
          () => EmailContact(name: '', email: from, source: 'recent'),
        );
      }
      final to = m.toAddr.trim();
      if (to.isNotEmpty && to.toLowerCase() != myAddr) {
        map.putIfAbsent(
          to.toLowerCase(),
          () => EmailContact(name: '', email: to, source: 'recent'),
        );
      }
    }

    return map.values.toList();
  }

  Widget _buildSearchRefreshRow({
    required TextEditingController controller,
    required String hintText,
    Widget? trailingSuffix,
    bool showCompose = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: UiInputDecoration.of(
                context,
                hintText: hintText,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailingSuffix != null) trailingSuffix,
                    IconButton(
                      onPressed: _listRefreshing ? null : () => unawaited(_load(refresh: true)),
                      tooltip: 'mail.refresh'.tr(),
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showCompose) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: !_canCompose ? null : () => unawaited(_openCompose()),
              tooltip: 'mail.compose'.tr(),
              icon: const Icon(Icons.add, size: 22),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListLoadingPane() {
    return const UILoading();
  }

  Future<void> _selectMailbox(MailMailbox mailbox) async {
    if (mailbox.mailboxId == _mailboxId) return;
    setState(() {
      _selectedMailboxId = mailbox.mailboxId;
      _activeMessage = null;
      _selectedIds.clear();
    });
    await _load(refresh: true);
  }

  Future<void> _showAccountSwitcher() async {
    if (_mailboxes.isEmpty && _account == null) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final activeId = _mailboxId;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.mark_email_read, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'mail.mailboxes'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final mb in _mailboxes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: mb.mailboxId == activeId
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: cs.primary,
                        child: Icon(
                          mb.kind == MailMailboxKind.site ? Icons.storefront_outlined : Icons.email,
                          color: cs.onPrimary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        mb.displayLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: mb.mailboxId == activeId ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(mb.address),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mb.unreadCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Badge(label: Text('${mb.unreadCount}')),
                            ),
                          if (mb.mailboxId == activeId)
                            Icon(Icons.check_circle, color: cs.primary),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        unawaited(_selectMailbox(mb));
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCompose({String? initialTo, String? initialSubject, String? initialBody, MailMessage? replyTo}) async {
    if (!_canCompose) return;
    final composeMailbox = _composeMailbox;
    if (composeMailbox == null) return;
    final contacts = _buildContactList();
    final composeDialog = _MailComposeDialog(
      chatConn: widget.chatConn,
      mailboxes: _mailboxes,
      mailboxId: composeMailbox.mailboxId,
      fromAddress: composeMailbox.address,
      onMailboxChanged: (mb) => unawaited(_selectMailbox(mb)),
      contacts: contacts,
      emailAvatars: _emailAvatars,
      initialTo: initialTo,
      initialSubject: initialSubject,
      initialBody: replyTo == null ? initialBody : null,
      replyTo: replyTo,
    );
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final useComposeDialog = !isCompact || kIsWeb;
    final sent = useComposeDialog
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 580,
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
                child: composeDialog,
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.92,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (_, __) => composeDialog,
            ),
          );
    if (sent == true && mounted) await _load();
  }

  Future<void> _openMessageForNotification(int messageId, int mailboxId) async {
    if (messageId <= 0 || !mounted) return;
    if (!_loaded) {
      _pendingNotifMessageId = messageId;
      _pendingNotifMailboxId = mailboxId > 0 ? mailboxId : 0;
      return;
    }
    if (mailboxId > 0 && mailboxId != _mailboxId) {
      if (_mailboxes.any((m) => m.mailboxId == mailboxId)) {
        await _switchMailbox(mailboxId);
      }
    }
    if (!mounted) return;
    if (_currentFolder != _MailFolder.inbox) {
      setState(() => _currentFolder = _MailFolder.inbox);
    }
    await _openMessageById(messageId, mailboxId: mailboxId);
  }

  Future<void> _switchMailbox(int mailboxId) async {
    if (mailboxId <= 0 || mailboxId == _mailboxId) return;
    setState(() {
      _selectedMailboxId = mailboxId;
      _activeMessage = null;
      _selectedIds.clear();
    });
    await _load(refresh: true);
  }

  Future<MailMessage?> _fetchMessageById(int messageId, {int mailboxId = 0}) async {
    final tried = <int>{};
    Future<MailMessage?> tryMb(int mbId) async {
      if (mbId <= 0 || tried.contains(mbId)) return null;
      tried.add(mbId);
      try {
        return await _mailApi.get(messageId, mailboxId: mbId);
      } catch (_) {
        return null;
      }
    }

    final hinted = await tryMb(mailboxId);
    if (hinted != null) return hinted;

    final accountMb = _account?.mailboxId ?? 0;
    final accountMsg = await tryMb(accountMb);
    if (accountMsg != null) return accountMsg;

    final currentMb = _mailboxId;
    final currentMsg = await tryMb(currentMb);
    if (currentMsg != null) return currentMsg;

    for (final mb in _mailboxes) {
      final msg = await tryMb(mb.mailboxId);
      if (msg != null) return msg;
    }
    return null;
  }

  Future<void> _openMessage(MailMessage message, {int mailboxId = 0}) async {
    final seq = ++_openMessageSeq;
    final openedId = message.messageId;
    setState(() {
      _activeMessage = message;
    });
    try {
      final mbId = mailboxId > 0 ? mailboxId : _mailboxId;
      final full = await _mailApi.get(message.messageId, mailboxId: mbId);
      if (!mounted || seq != _openMessageSeq) return;
      if (_activeMessage?.messageId != openedId) return;
      final markedRead = full.direction == MailDirection.inbound && !message.isRead && full.isRead;
      _patchMessage(full);
      setState(() {
        _activeMessage = full;
      });
      if (markedRead) {
        _syncInboxBadge();
      }
    } catch (e, st) {
      lError('$e\n$st');
    }
  }

  int _unreadInboxCount() =>
      _inbox.where((m) => m.direction == MailDirection.inbound && !m.isRead).length;

  void _syncInboxBadge() {
    mailInboxBus.setCount(_unreadInboxCount());
  }

  void _patchMessage(MailMessage updated) {
    void patch(List<MailMessage> list) {
      final i = list.indexWhere((m) => m.messageId == updated.messageId);
      if (i >= 0) list[i] = updated;
    }
    patch(_inbox);
    patch(_outbox);
    patch(_archived);
    patch(_drafts);
    patch(_spam);
  }

  Future<void> _openMessageById(int messageId, {int mailboxId = 0}) async {
    if (messageId <= 0 || !mounted) return;
    MailMessage? message;
    for (final m in _inbox) {
      if (m.messageId == messageId) {
        message = m;
        break;
      }
    }
    if (message == null) {
      for (final m in _outbox) {
        if (m.messageId == messageId) {
          message = m;
          break;
        }
      }
    }
    if (message == null) {
      for (final m in _archived) {
        if (m.messageId == messageId) {
          message = m;
          break;
        }
      }
    }
    if (message == null) {
      message = await _fetchMessageById(messageId, mailboxId: mailboxId);
      if (message == null) {
        lError('mail message not found: $messageId');
        return;
      }
    }
    if (!mounted) return;
    await _openMessage(message, mailboxId: mailboxId);
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<MailMessage> _currentFolderMessages() {
    switch (_currentFolder) {
      case _MailFolder.inbox:
        return _inbox;
      case _MailFolder.sent:
        return _outbox;
      case _MailFolder.archive:
        return _archived;
      case _MailFolder.draft:
        return _drafts;
      case _MailFolder.spam:
        return _spam;
      default:
        return [];
    }
  }

  List<MailMessage> _filterMessages(List<MailMessage> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((m) {
      final peer = m.direction == MailDirection.inbound ? m.fromAddr : m.toAddr;
      return peer.toLowerCase().contains(_searchQuery) ||
          m.subject.toLowerCase().contains(_searchQuery) ||
          m.bodyText.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _selectAllCurrentFolder() {
    final filtered = _filterMessages(_currentFolderMessages());
    setState(() {
      _selectedIds.addAll(filtered.map((m) => m.messageId));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _batchArchiveSelected() async {
    if (_selectedIds.isEmpty) return;
    final messagesToArchive = [
      ..._inbox.where((m) => _selectedIds.contains(m.messageId)),
      ..._outbox.where((m) => _selectedIds.contains(m.messageId)),
      ..._archived.where((m) => _selectedIds.contains(m.messageId)),
    ];
    await _archiveMessagesWithUndo(messagesToArchive);
  }

  Future<void> _archiveSingle(MailMessage msg) async {
    await _archiveMessagesWithUndo([msg]);
  }

  Future<void> _archiveMessagesWithUndo(List<MailMessage> messages) async {
    if (messages.isEmpty) return;
    final ids = messages.map((m) => m.messageId).toList();

    setState(() {
      _inbox.removeWhere((m) => ids.contains(m.messageId));
      _outbox.removeWhere((m) => ids.contains(m.messageId));
      for (final m in messages) {
        if (!_archived.any((item) => item.messageId == m.messageId)) {
          _archived.add(m);
        }
      }
      if (_activeMessage != null && ids.contains(_activeMessage!.messageId)) {
        _activeMessage = null;
      }
      _selectedIds.clear();
    });

    try {
      await _mailApi.archive(messageIds: ids, mailboxId: _mailboxId, archive: true);
    } catch (e, st) {
      lError('$e\n$st');
    }

    if (!mounted) return;
    final count = messages.length;
    final text = '$count email berhasil diarsipkan';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(_undoArchive(messages)),
        ),
      ),
    );
  }

  Future<void> _undoArchive(List<MailMessage> messages) async {
    if (messages.isEmpty) return;
    final ids = messages.map((m) => m.messageId).toList();

    setState(() {
      _archived.removeWhere((m) => ids.contains(m.messageId));
      for (final m in messages) {
        if (m.direction == MailDirection.inbound) {
          if (!_inbox.any((item) => item.messageId == m.messageId)) {
            _inbox.add(m);
          }
        } else {
          if (!_outbox.any((item) => item.messageId == m.messageId)) {
            _outbox.add(m);
          }
        }
      }
    });

    try {
      await _mailApi.archive(messageIds: ids, mailboxId: _mailboxId, archive: false);
    } catch (e, st) {
      lError('$e\n$st');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batal mengarsipkan email'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _batchDeleteSelected() {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _inbox.removeWhere((m) => _selectedIds.contains(m.messageId));
      _outbox.removeWhere((m) => _selectedIds.contains(m.messageId));
      _archived.removeWhere((m) => _selectedIds.contains(m.messageId));
      _drafts.removeWhere((m) => _selectedIds.contains(m.messageId));
      _spam.removeWhere((m) => _selectedIds.contains(m.messageId));

      if (_activeMessage != null && _selectedIds.contains(_activeMessage!.messageId)) {
        _activeMessage = null;
      }
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('mail.delete'.tr())),
    );
  }

  void _deleteSingle(MailMessage msg) {
    setState(() {
      _inbox.removeWhere((m) => m.messageId == msg.messageId);
      _outbox.removeWhere((m) => m.messageId == msg.messageId);
      _archived.removeWhere((m) => m.messageId == msg.messageId);
      _drafts.removeWhere((m) => m.messageId == msg.messageId);
      _spam.removeWhere((m) => m.messageId == msg.messageId);
      if (_activeMessage?.messageId == msg.messageId) {
        _activeMessage = null;
      }
    });
  }

  Widget _buildMasterRail(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: _showAccountSwitcher,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primary,
                      child: Icon(Icons.email, size: 16, color: cs.onPrimary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('mail.title'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (_activeAddress.isNotEmpty)
                            Text(
                              _activeAddress,
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: !_canCompose ? null : () => _openCompose(),
              icon: const Icon(Icons.add, size: 18),
              label: Text('mail.compose'.tr()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(_MailFolder.contacts),
                _buildNavItem(_MailFolder.mailingList),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Divider(height: 1),
                ),
                _buildNavItem(_MailFolder.inbox, badgeCount: _unreadInboxCount()),
                _buildNavItem(_MailFolder.sent),
                _buildNavItem(_MailFolder.draft, badgeCount: _drafts.length),
                _buildNavItem(_MailFolder.archive, badgeCount: _archived.length),
                _buildNavItem(_MailFolder.spam, badgeCount: _spam.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_MailFolder folder, {int badgeCount = 0}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _currentFolder == folder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? cs.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            folder.icon,
            size: 20,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(
            folder.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
          trailing: badgeCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              _currentFolder = folder;
              _selectedIds.clear();
              _activeMessage = null;
              _mailingListDrill = false;
              _mailingListDrillTitle = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDetailCanvas() {
    if (_activeMessage != null) {
      return _buildMessageDetail(embedded: false);
    }

    return _buildFolderContent();
  }

  Widget _buildFolderContent() {
    switch (_currentFolder) {
      case _MailFolder.contacts:
        return _MailContactsPane(
          contacts: _buildContactList(),
          emailAvatars: _emailAvatars,
          refreshing: _listRefreshing,
          onRefresh: () => _load(refresh: true),
          onComposeTo: (email) => _openCompose(initialTo: email),
        );
      case _MailFolder.mailingList:
        return _MailMailingListPane(
          key: _mailingListPaneKey,
          account: _account,
          chatConn: widget.chatConn,
          mailboxId: _mailboxId,
          emailAvatars: _emailAvatars,
          groups: _mailingLists,
          subscriberLimit: _subscriberLimit,
          canWrite: _canWriteMailbox,
          refreshing: _listRefreshing,
          onRefresh: () => _load(refresh: true),
          onSendBroadcast: _handleBroadcast,
          onSaveGroups: () async {},
          onDrillChanged: (drilled, title) {
            setState(() {
              _mailingListDrill = drilled;
              _mailingListDrillTitle = title;
            });
          },
        );
      case _MailFolder.inbox:
        return _buildFolderPane('mail.inboxEmpty'.tr(), _inbox);
      case _MailFolder.sent:
        return _buildFolderPane('mail.outboxEmpty'.tr(), _outbox);
      case _MailFolder.draft:
        return _buildFolderPane('No drafts', _drafts);
      case _MailFolder.archive:
        return _buildFolderPane('mail.archivedEmpty'.tr(), _archived);
      case _MailFolder.spam:
        return _buildFolderPane('No spam messages', _spam);
    }
  }

  Widget _buildMessageDetail({required bool embedded}) {
    final message = _activeMessage;
    if (message == null) return const SizedBox.shrink();
    return _MailDetailPageView(
      embedded: embedded,
      account: _account,
      message: message,
      emailAvatars: _emailAvatars,
      onBack: () => setState(() => _activeMessage = null),
      onArchive: () => _archiveSingle(message),
      onDelete: () => _deleteSingle(message),
      onReply: (to, subj, msg) => _openCompose(
        initialTo: to,
        initialSubject: subj,
        replyTo: msg,
      ),
    );
  }

  Widget _buildMessageDetailPlaceholder() {
    return UINotFound(
      icon: Icons.mail_outline,
      title: 'mail.selectMessage'.tr(),
      subtitle: 'mail.selectMessageHint'.tr(),
    );
  }

  Widget _buildMasterDetailLayout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMasterRail(context),
        SizedBox(
          width: _mailMasterListWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            child: _buildFolderContent(),
          ),
        ),
        Expanded(
          child: _activeMessage != null
              ? _buildMessageDetail(embedded: true)
              : _buildMessageDetailPlaceholder(),
        ),
      ],
    );
  }

  bool _useMasterDetail(double width) =>
      width >= _mailMasterDetailBreakpoint &&
      width >= _mailRailBreakpoint &&
      _currentFolder.isMessageFolder;

  Future<void> _handleBroadcast(
      String groupId, String subject, String body, {List<MailAttachment> attachments = const []}) async {
    if (!_canWriteMailbox) return;
    try {
      final result = await _mailApi.broadcast(
        mailboxId: _mailboxId,
        groupId: groupId,
        subject: subject,
        bodyText: body,
        attachments: attachments,
      );
      if (!mounted) return;
      if (result.failures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mail.broadcastSent'.tr(namedArgs: {'count': '${result.sentCount}'}))),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('mail.broadcastPartial'.tr()),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'mail.broadcastPartialSummary'.tr(
                      namedArgs: {
                        'sent': '${result.sentCount}',
                        'failed': '${result.failures.length}',
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final f in result.failures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${f.toAddr}: ${f.error}',
                        style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      await _load();
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send broadcast: ${uiFriendlyError(e)}')),
      );
    }
  }

  Widget _buildFolderPane(String emptyTitle, List<MailMessage> list) {
    final filtered = _filterMessages(list);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchRefreshRow(
          controller: _searchCtrl,
          hintText: 'mail.search'.tr(),
          showCompose: MediaQuery.sizeOf(context).width < _mailRailBreakpoint,
          trailingSuffix: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
        ),
        Expanded(
          child: _listRefreshing && !_loaded
              ? _buildListLoadingPane()
              : _error != null && filtered.isEmpty
                  ? UINotFoundScrollable(
                      icon: Icons.error_outline,
                      title: 'mail.loadFailed'.tr(),
                      subtitle: _error,
                    )
                  : _MailListPane(
                      emptyTitle: emptyTitle,
                      messages: filtered,
                      selectedIds: _selectedIds,
                      selectionMode: _selectedIds.isNotEmpty,
                      activeMessageId: _activeMessage?.messageId,
                      emailAvatars: _emailAvatars,
                      refreshing: _listRefreshing,
                      onEnterSelectionMode: _enterSelectionMode,
                      onToggleSelect: _toggleSelect,
                      onTap: _openMessage,
                      onRefresh: () => _load(refresh: true),
                    ),
        ),
      ],
    );
  }

  void _popMailingListDrill() {
    final pane = _mailingListPaneKey.currentState;
    if (pane != null) {
      pane.backToMaster();
    } else if (_mailingListDrill) {
      setState(() {
        _mailingListDrill = false;
        _mailingListDrillTitle = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.canUseMail && !_loaded) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'common.back'.tr(),
            onPressed: () => Navigator.maybePop(context),
          ),
          automaticallyImplyLeading: false,
          title: Text('mail.title'.tr()),
        ),
        body: const UILoading(),
      );
    }
    if (!Session.instance.canUseMail && _loaded && _mailboxes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'common.back'.tr(),
            onPressed: () => Navigator.maybePop(context),
          ),
          automaticallyImplyLeading: false,
          title: Text('mail.title'.tr()),
        ),
        body: UINotFound(
          icon: Icons.mail_outlined,
          title: 'mail.forbidden'.tr(),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelecting = _selectedIds.isNotEmpty;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < _mailRailBreakpoint;
    final masterDetail = _useMasterDetail(width);
    final mailingListDrill = narrow && _currentFolder == _MailFolder.mailingList && _mailingListDrill;
    final hideFolderChips = narrow && (_activeMessage != null || mailingListDrill);
    final showOuterAppBar = _activeMessage == null || masterDetail;

    return Scaffold(
      appBar: showOuterAppBar
          ? AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'common.back'.tr(),
          onPressed: mailingListDrill ? _popMailingListDrill : () => Navigator.maybePop(context),
        ),
        automaticallyImplyLeading: false,
        title: isSelecting
            ? Text(
                'mail.selected'.tr(namedArgs: {'count': '${_selectedIds.length}'}),
                style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
              )
            : Text(
                mailingListDrill && _mailingListDrillTitle != null
                    ? _mailingListDrillTitle!
                    : _currentFolder.label,
              ),
        actions: isSelecting
            ? [
                TextButton(
                  onPressed: _selectAllCurrentFolder,
                  child: Text('mail.selectAll'.tr()),
                ),
                IconButton(
                  tooltip: 'mail.archive'.tr(),
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: _batchArchiveSelected,
                ),
                IconButton(
                  tooltip: 'mail.delete'.tr(),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _batchDeleteSelected,
                ),
                IconButton(
                  tooltip: 'mail.deselectAll'.tr(),
                  icon: const Icon(Icons.close),
                  onPressed: _deselectAll,
                ),
              ]
            : [
                IconButton(
                  tooltip: 'mail.mailboxes'.tr(),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  onPressed: _showAccountSwitcher,
                ),
              ],
      )
          : null,
      body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_useMasterDetail(constraints.maxWidth)) {
                      return _buildMasterDetailLayout(context);
                    }
                    if (constraints.maxWidth >= _mailRailBreakpoint) {
                      return Row(
                        children: [
                          _buildMasterRail(context),
                          Expanded(child: _buildDetailCanvas()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        if (!hideFolderChips)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                _buildChipFolder(_MailFolder.contacts),
                                const SizedBox(width: 6),
                                _buildChipFolder(_MailFolder.mailingList),
                                const SizedBox(width: 8),
                                const SizedBox(height: 20, child: VerticalDivider(width: 1)),
                                const SizedBox(width: 8),
                                _buildChipFolder(_MailFolder.inbox),
                                const SizedBox(width: 6),
                                _buildChipFolder(_MailFolder.sent),
                                const SizedBox(width: 6),
                                _buildChipFolder(_MailFolder.draft),
                                const SizedBox(width: 6),
                                _buildChipFolder(_MailFolder.archive),
                                const SizedBox(width: 6),
                                _buildChipFolder(_MailFolder.spam),
                              ],
                            ),
                          ),
                        Expanded(child: _buildDetailCanvas()),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildChipFolder(_MailFolder folder) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _currentFolder == folder;

    return ChoiceChip(
      selected: selected,
      avatar: Icon(folder.icon, size: 16, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
      label: Text(folder.label),
      onSelected: (_) {
        setState(() {
          _currentFolder = folder;
          _selectedIds.clear();
          _activeMessage = null;
          _mailingListDrill = false;
          _mailingListDrillTitle = null;
        });
      },
    );
  }
}

class _MailContactsPane extends StatefulWidget {
  const _MailContactsPane({
    required this.contacts,
    required this.emailAvatars,
    required this.refreshing,
    required this.onRefresh,
    required this.onComposeTo,
  });

  final List<EmailContact> contacts;
  final MailEmailAvatarResolver emailAvatars;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onComposeTo;

  @override
  State<_MailContactsPane> createState() => _MailContactsPaneState();
}

class _MailContactsPaneState extends State<_MailContactsPane> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.contacts.where((c) {
      if (_query.isEmpty) return true;
      return c.name.toLowerCase().contains(_query) || c.email.toLowerCase().contains(_query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: UiInputDecoration.of(
                      context,
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: widget.refreshing ? null : () => unawaited(widget.onRefresh()),
                  tooltip: 'mail.refresh'.tr(),
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.refreshing && widget.contacts.isEmpty
                ? const UILoading()
                : filtered.isEmpty
                ? UINotFound(icon: Icons.contacts_outlined, title: 'No contacts found')
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: UiMailEmailAvatar(
                          email: c.email,
                          hintUrl: c.avatarUrl,
                          resolver: widget.emailAvatars,
                          radius: 20,
                        ),
                        title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.email),
                        trailing: OutlinedButton.icon(
                          onPressed: () => widget.onComposeTo(c.email),
                          icon: const Icon(Icons.mail_outlined, size: 16),
                          label: const Text('Email'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MailMailingListPane extends StatefulWidget {
  const _MailMailingListPane({
    super.key,
    required this.account,
    required this.chatConn,
    required this.groups,
    required this.mailboxId,
    required this.emailAvatars,
    required this.subscriberLimit,
    required this.canWrite,
    required this.refreshing,
    required this.onRefresh,
    required this.onSendBroadcast,
    required this.onSaveGroups,
    this.onDrillChanged,
  });

  final MailAccount? account;
  final ChatConn chatConn;
  final int mailboxId;
  final MailEmailAvatarResolver emailAvatars;
  final List<MailingListGroup> groups;
  final int subscriberLimit;
  final bool canWrite;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String groupId, String subject, String body, {List<MailAttachment> attachments}) onSendBroadcast;
  final Future<void> Function() onSaveGroups;
  final void Function(bool drilled, String? title)? onDrillChanged;

  @override
  State<_MailMailingListPane> createState() => _MailMailingListPaneState();
}

class _MailMailingListPaneState extends State<_MailMailingListPane> {
  MailApi get _mailApi => MailApi(widget.chatConn);

  int get _subscriberLimit => widget.subscriberLimit > 0 ? widget.subscriberLimit : 1000;

  int _selectedGroupIdx = 0;
  bool _detailDrill = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _addEmailCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _addEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddSubscribersDialog(MailingListGroup group) async {
    final remaining = _subscriberLimit - group.emails.length;
    if (remaining <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscriber limit reached. Contact us to request a higher limit.'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    final textCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subscribers'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter email addresses below (one per line, or separated by commas):',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                minLines: 5,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                autofocus: true,
                decoration: UiInputDecoration.of(
                  ctx,
                  hintText: 'chito@alienai.id\npartner@alienai.id\nsupport@alienai.id',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Subscribers'),
          ),
        ],
      ),
    );

    if (added == true && textCtrl.text.trim().isNotEmpty && mounted) {
      final raw = textCtrl.text;
      final tokens = raw
          .split(RegExp(r'[\n\r,;\s]+'))
          .map((s) => s.trim())
          .where((s) => s.contains('@') && s.contains('.'))
          .toList();

      if (tokens.isEmpty) return;

      final remaining = _subscriberLimit - group.emails.length;
      final allowed = tokens.take(remaining).toList();
      final skipped = tokens.length - allowed.length;

      int addedCount = 0;
      setState(() {
        for (final email in allowed) {
          if (!group.emails.contains(email)) {
            group.emails.add(email);
            addedCount++;
          }
        }
      });

      if (addedCount > 0) {
        try {
          await _mailApi.groupUpsert(mailboxId: widget.mailboxId, group: group);
        } catch (e, st) {
          lError('$e\n$st');
        }

        if (!mounted) return;
        final msg = skipped > 0
            ? '$addedCount subscriber(s) added. $skipped skipped ΓÇö limit of $_subscriberLimit reached.'
            : '$addedCount subscriber(s) added to ${group.name}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveRecipient(MailingListGroup group, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Subscriber'),
        content: Text('Are you sure you want to remove "$email" from ${group.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        group.emails.remove(email);
      });
      try {
        await _mailApi.groupUpsert(mailboxId: widget.mailboxId, group: group);
      } catch (e, st) {
        lError('$e\n$st');
      }
    }
  }

  Future<void> _confirmDeleteGroup(MailingListGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mailing List'),
        content: Text('Are you sure you want to delete mailing list "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        widget.groups.removeWhere((g) => g.id == group.id);
        _selectedGroupIdx = 0;
      });
      try {
        await _mailApi.groupDelete(mailboxId: widget.mailboxId, groupId: group.id);
      } catch (e, st) {
        lError('$e\n$st');
      }
    }
  }

  Future<void> _createNewGroup() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Mailing List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              maxLength: 60,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: UiInputDecoration.of(ctx, labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: UiInputDecoration.of(ctx, labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      final newGroup = MailingListGroup(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        emails: [],
      );
      setState(() {
        widget.groups.add(newGroup);
        _selectedGroupIdx = widget.groups.length - 1;
      });
      try {
        await _mailApi.groupUpsert(mailboxId: widget.mailboxId, group: newGroup);
      } catch (e, st) {
        lError('$e\n$st');
      }
    }
  }

  Future<void> _composeBroadcast(MailingListGroup group) async {
    final result = await showDialog<_BroadcastPayload>(
      context: context,
      builder: (ctx) => _BroadcastComposeDialog(groupName: group.name, recipientCount: group.emails.length),
    );
    if (result == null || !mounted) return;

    // ΓöÇΓöÇ Confirmation dialog ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.campaign_outlined, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Confirm Broadcast'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(label: 'List', value: group.name),
            _ConfirmRow(label: 'Recipients', value: '${group.emails.length} subscriber(s)'),
            _ConfirmRow(label: 'Subject', value: result.subject),
            if (result.attachments.isNotEmpty)
              _ConfirmRow(label: 'Attachments', value: '${result.attachments.length} file(s)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will send an email to every subscriber in the list. This action cannot be undone.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.send, size: 16),
            label: Text('Send to ${group.emails.length}'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await widget.onSendBroadcast(group.id, result.subject, result.body, attachments: result.attachments);
  }

  void _selectGroup(int index) {
    setState(() {
      _selectedGroupIdx = index;
      _detailDrill = true;
    });
    widget.onDrillChanged?.call(true, widget.groups[index].name);
  }

  void backToMaster() => _backToMaster();

  void _backToMaster() {
    if (!_detailDrill) return;
    setState(() => _detailDrill = false);
    widget.onDrillChanged?.call(false, null);
  }

  Widget _buildGroupsMasterPane({required bool masterDetail}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasGroups = widget.groups.isNotEmpty;

    return ColoredBox(
      color: masterDetail ? cs.surfaceContainerLow : cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mailing Lists',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'New List',
                  onPressed: _createNewGroup,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !hasGroups
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No lists yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    itemCount: widget.groups.length,
                    itemBuilder: (context, i) {
                      final g = widget.groups[i];
                      final isSel = i == _selectedGroupIdx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: isSel ? cs.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            title: Text(
                              g.name,
                              style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                            ),
                            subtitle: Row(
                              children: [
                                Text('${g.emails.length} subscribers'),
                                const SizedBox(width: 6),
                                _SubscriberLimitBadge(
                                  current: g.emails.length,
                                  limit: _subscriberLimit,
                                  compact: true,
                                ),
                              ],
                            ),
                            onTap: () {
                              if (masterDetail) {
                                setState(() => _selectedGroupIdx = i);
                              } else {
                                _selectGroup(i);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetailPane(MailingListGroup selectedGroup, {required bool showTitle}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filteredEmails = selectedGroup.emails.where((e) {
      if (_query.isEmpty) return true;
      return e.toLowerCase().contains(_query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle) ...[
            Text(
              selectedGroup.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SubscriberLimitBadge(
                  current: selectedGroup.emails.length,
                  limit: _subscriberLimit,
                  compact: false,
                ),
                if (selectedGroup.description.trim().isNotEmpty)
                  Text(
                    selectedGroup.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SubscriberLimitBadge(
                  current: selectedGroup.emails.length,
                  limit: _subscriberLimit,
                  compact: false,
                ),
                if (selectedGroup.description.trim().isNotEmpty)
                  Text(
                    selectedGroup.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: selectedGroup.emails.isEmpty ? null : () => _composeBroadcast(selectedGroup),
                icon: const Icon(Icons.send, size: 18),
                label: Text('Broadcast (${selectedGroup.emails.length})'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddSubscribersDialog(selectedGroup),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Subscribers'),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                tooltip: 'Delete Mailing List',
                onPressed: () => _confirmDeleteGroup(selectedGroup),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: UiInputDecoration.of(
                    context,
                    hintText: 'Search subscribers...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() => _query = val.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: widget.refreshing ? null : () => unawaited(widget.onRefresh()),
                tooltip: 'mail.refresh'.tr(),
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredEmails.isEmpty
                ? UINotFound(icon: Icons.people_outline, title: 'No subscribers in list')
                : ListView.separated(
                    itemCount: filteredEmails.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final email = filteredEmails[i];
                      return ListTile(
                        leading: UiMailEmailAvatar(
                          email: email,
                          resolver: widget.emailAvatars,
                          radius: 16,
                        ),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: cs.error, size: 20),
                          tooltip: 'Remove from list',
                          onPressed: () => _confirmRemoveRecipient(selectedGroup, email),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasGroups = widget.groups.isNotEmpty;
    final selectedGroup = hasGroups
        ? widget.groups[_selectedGroupIdx.clamp(0, widget.groups.length - 1)]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final masterDetail = constraints.maxWidth >= _mailMailingListMasterDetailBreakpoint;

        if (!hasGroups) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 48, color: cs.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No Mailing Lists', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Create your first list to organize subscribers for broadcasts.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _createNewGroup,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Mailing List'),
                ),
              ],
            ),
          );
        }

        if (masterDetail) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: siteCatalogMasterListW,
                child: _buildGroupsMasterPane(masterDetail: true),
              ),
              siteCatalogMasterDivider(context),
              Expanded(child: _buildGroupDetailPane(selectedGroup!, showTitle: true)),
            ],
          );
        }

        if (_detailDrill && selectedGroup != null) {
          return _buildGroupDetailPane(selectedGroup, showTitle: false);
        }

        return _buildGroupsMasterPane(masterDetail: false);
      },
    );
  }
}

class _BroadcastPayload {
  _BroadcastPayload({
    required this.subject,
    required this.body,
    this.attachments = const [],
  });

  final String subject;
  final String body;
  final List<MailAttachment> attachments;
}

class _BroadcastComposeDialog extends StatefulWidget {
  const _BroadcastComposeDialog({
    required this.groupName,
    required this.recipientCount,
  });

  final String groupName;
  final int recipientCount;

  @override
  State<_BroadcastComposeDialog> createState() => _BroadcastComposeDialogState();
}

class _BroadcastComposeDialogState extends State<_BroadcastComposeDialog> {
  final TextEditingController _subjectCtrl = TextEditingController();
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _editorFocus = FocusNode();
  late final EditorState _editorState;
  late final EditorScrollController _editorScrollController;
  late final MailStagedAttachmentsController _attachments;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attachments = MailStagedAttachmentsController(onChanged: () {
      if (mounted) setState(() {});
    });
    _editorState = EditorState(document: Document.blank(withInitialText: true));
    _editorScrollController = EditorScrollController(
      editorState: _editorState,
      shrinkWrap: false,
    );
    _ensureEditorSelectionOnFocus(_editorState, _editorFocus);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _subjectFocus.dispose();
    _editorFocus.dispose();
    _editorScrollController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    if (_attachments.items.length >= mailStagedAttachmentMaxCount) return;
    try {
      final tooLarge = await _attachments.pickAndStage(context: context);
      if (!mounted) return;
      setState(() {
        _error = tooLarge != null
            ? 'mail.attachmentTooLarge'.tr(namedArgs: {'name': tooLarge})
            : null;
      });
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      setState(() => _error = uiFriendlyError(e));
    }
  }

  Future<void> _onSend() async {
    final subj = _subjectCtrl.text.trim();
    final body = documentToMarkdown(_editorState.document).trim();
    if (subj.isEmpty || !_attachments.canSend) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      Navigator.of(context).pop(
        _BroadcastPayload(
          subject: subj,
          body: body,
          attachments: _attachments.readyAttachments(),
        ),
      );
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final content = FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isCompact)
            Row(
              children: [
                Icon(Icons.campaign, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Broadcast ΓÇö ${widget.groupName}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          if (isCompact) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.campaign, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sending to ${widget.recipientCount} recipient(s)',
                      style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          if (!isCompact) const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0, vertical: isCompact ? 4 : 0),
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: TextField(
                controller: _subjectCtrl,
                focusNode: _subjectFocus,
                textInputAction: TextInputAction.next,
                decoration: isCompact
                    ? const InputDecoration(
                        hintText: 'Subject',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      )
                    : UiInputDecoration.of(context, labelText: 'Subject'),
                onSubmitted: (_) => _editorFocus.requestFocus(),
              ),
            ),
          ),
          if (isCompact) const Divider(height: 1),
          if (!isCompact) const SizedBox(height: 12),
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: Container(
                margin: EdgeInsets.all(isCompact ? 12 : 0),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.all(8),
                child: AppFlowyEditor(
                  editorState: _editorState,
                  editorScrollController: _editorScrollController,
                  focusNode: _editorFocus,
                  editorStyle: isCompact
                      ? EditorStyle.mobile(
                          padding: const EdgeInsets.all(4),
                          cursorColor: cs.primary,
                          selectionColor: cs.primary.withValues(alpha: 0.25),
                          textStyleConfiguration: TextStyleConfiguration(
                            text: TextStyle(fontSize: 15, height: 1.4, color: cs.onSurface),
                          ),
                        )
                      : EditorStyle.desktop(
                          padding: const EdgeInsets.all(8),
                          cursorColor: cs.primary,
                          textStyleConfiguration: TextStyleConfiguration(
                            text: TextStyle(color: cs.onSurface, fontSize: 14),
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (_attachments.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0),
                scrollDirection: Axis.horizontal,
                itemCount: _attachments.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final f = _attachments.items[i];
                  final isImage = f.isImage;
                  final failed = f.error != null && f.error!.isNotEmpty;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: failed ? () => unawaited(_attachments.retryAt(i)) : null,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: failed ? cs.error : cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isImage)
                                Image.memory(
                                  f.bytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _AttachIcon(mime: f.mime, cs: cs),
                                )
                              else
                                _AttachIcon(mime: f.mime, cs: cs),
                              if (f.uploading)
                                const ColoredBox(
                                  color: Colors.black38,
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                  ),
                                ),
                              if (failed)
                                ColoredBox(
                                  color: cs.error.withValues(alpha: 0.35),
                                  child: Center(
                                    child: Icon(Icons.refresh, color: cs.onErrorContainer, size: 28),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                          child: Text(
                            f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                      if (!_sending)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => _attachments.removeAt(i),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: cs.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0),
              child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
            ),
          ],
          if (!isCompact) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: OutlinedButton.icon(
                    onPressed: _sending || _attachments.items.length >= mailStagedAttachmentMaxCount
                        ? null
                        : () => unawaited(_pickAttachments()),
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      'Attach${_attachments.items.isNotEmpty ? ' (${_attachments.items.length})' : ''}',
                    ),
                  ),
                ),
                const Spacer(),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: TextButton(
                    onPressed: _sending ? null : () => Navigator.of(context).pop(),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: FilledButton.icon(
                    onPressed: _sending || !_attachments.canSend ? null : _onSend,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text('Send (${widget.recipientCount})'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Broadcast ΓÇö ${widget.groupName}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                tooltip: 'mail.attach'.tr(),
                onPressed: _sending || _attachments.items.length >= mailStagedAttachmentMaxCount
                    ? null
                    : () => unawaited(_pickAttachments()),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _sending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton.filled(
                        onPressed: _sending || !_attachments.canSend ? null : _onSend,
                        icon: const Icon(Icons.send, size: 18),
                        tooltip: 'Send',
                      ),
              ),
            ],
          ),
          body: SafeArea(child: content),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 640),
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}

class _MailListPane extends StatelessWidget {
  const _MailListPane({
    required this.emptyTitle,
    required this.messages,
    required this.selectedIds,
    required this.selectionMode,
    this.activeMessageId,
    required this.emailAvatars,
    required this.refreshing,
    required this.onEnterSelectionMode,
    required this.onToggleSelect,
    required this.onTap,
    required this.onRefresh,
  });

  final String emptyTitle;
  final List<MailMessage> messages;
  final Set<int> selectedIds;
  final bool selectionMode;
  final int? activeMessageId;
  final MailEmailAvatarResolver emailAvatars;
  final bool refreshing;
  final ValueChanged<int> onEnterSelectionMode;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<MailMessage> onTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget listContent;
    if (messages.isEmpty) {
      listContent = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: UINotFound(icon: Icons.inbox_outlined, title: emptyTitle),
          ),
        ],
      );
    } else {
      listContent = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final isBatchSelected = selectedIds.contains(m.messageId);
          final isActive = activeMessageId == m.messageId;
          return _MailCardTile(
            message: m,
            isSelected: isBatchSelected,
            selectionMode: selectionMode,
            isActive: isActive,
            emailAvatars: emailAvatars,
            onEnterSelectionMode: () => onEnterSelectionMode(m.messageId),
            onToggleSelect: () => onToggleSelect(m.messageId),
            onTap: () => onTap(m),
          );
        },
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: listContent,
        ),
        if (refreshing)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
              child: const Center(child: UILoading(compact: true)),
            ),
          ),
      ],
    );
  }
}

class _MailCardTile extends StatelessWidget {
  const _MailCardTile({
    required this.message,
    required this.isSelected,
    required this.selectionMode,
    this.isActive = false,
    required this.emailAvatars,
    required this.onEnterSelectionMode,
    required this.onToggleSelect,
    required this.onTap,
  });

  final MailMessage message;
  final bool isSelected;
  final bool selectionMode;
  final bool isActive;
  final MailEmailAvatarResolver emailAvatars;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onToggleSelect;
  final VoidCallback onTap;

  static const _avatarRadius = 15.0;

  Widget _buildLeading(ThemeData theme, ColorScheme cs) {
    final peer = message.direction == MailDirection.inbound ? message.fromAddr : message.toAddr;
    if (selectionMode) {
      return IgnorePointer(
        child: SizedBox(
          width: _avatarRadius * 2,
          height: _avatarRadius * 2,
          child: Center(
            child: Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) {},
                activeColor: cs.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
      );
    }
    return UiMailEmailAvatar(
      email: peer,
      resolver: emailAvatars,
      radius: _avatarRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final peer = message.direction == MailDirection.inbound ? message.fromAddr : message.toAddr;
    final subjectText = message.subject.isEmpty ? 'mail.noSubject'.tr() : message.subject;
    final isUnread = message.direction == MailDirection.inbound && !message.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : isSelected
                ? cs.primaryContainer.withValues(alpha: 0.3)
                : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isActive || isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selectionMode ? onToggleSelect : onTap,
          onLongPress: selectionMode
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onEnterSelectionMode();
                },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLeading(theme, cs),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    peer,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                      height: 1.15,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (message.direction == MailDirection.outbound &&
                                    message.status == MailStatus.failed) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Icons.error_outline, size: 14, color: cs.error),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                if (message.attachments.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Icons.attach_file, size: 14, color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatWhen(message.createdAt),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: isUnread
                                          ? DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: cs.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: subjectText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                      height: 1.15,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  if (message.preview.isNotEmpty) ...[
                                    TextSpan(
                                      text: ' ΓÇö ',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    TextSpan(
                                      text: message.preview,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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

  String _formatWhen(int ms) {
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt);
    }
    return DateFormat.MMMd().format(dt);
  }
}

class _MailDetailPageView extends StatelessWidget {
  const _MailDetailPageView({
    required this.embedded,
    required this.account,
    required this.message,
    required this.emailAvatars,
    required this.onBack,
    required this.onArchive,
    required this.onDelete,
    required this.onReply,
  });

  final bool embedded;
  final MailAccount? account;
  final MailMessage message;
  final MailEmailAvatarResolver emailAvatars;
  final VoidCallback onBack;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final void Function(String to, String subject, MailMessage message) onReply;

  Widget _buildBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final peerAddress = message.direction == MailDirection.inbound ? message.fromAddr : message.toAddr;
    final replySubject = message.subject.toLowerCase().startsWith('re:') ? message.subject : 'Re: ${message.subject}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MailThreadItemCard(
                message: message,
                isLatest: true,
                emailAvatars: emailAvatars,
                onReplyItem: () => onReply(peerAddress, replySubject, message),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Material(
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onReply(peerAddress, replySubject, message),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.reply, size: 18, color: cs.onSurface),
                    const SizedBox(width: 8),
                    Text('mail.reply'.tr()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subjectTitle = message.subject.isEmpty ? 'mail.noSubject'.tr() : message.subject;
    final peerAddress = message.direction == MailDirection.inbound ? message.fromAddr : message.toAddr;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (!embedded)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'common.back'.tr(),
              onPressed: onBack,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  peerAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'mail.archive'.tr(),
            icon: const Icon(Icons.archive_outlined),
            onPressed: onArchive,
          ),
          IconButton(
            tooltip: 'mail.delete'.tr(),
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectTitle = message.subject.isEmpty ? 'mail.noSubject'.tr() : message.subject;

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'common.back'.tr(),
          onPressed: onBack,
        ),
        title: Text(subjectTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'mail.archive'.tr(),
            icon: const Icon(Icons.archive_outlined),
            onPressed: onArchive,
          ),
          IconButton(
            tooltip: 'mail.delete'.tr(),
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}

class _MailThreadItemCard extends StatefulWidget {
  const _MailThreadItemCard({
    required this.message,
    required this.isLatest,
    required this.emailAvatars,
    required this.onReplyItem,
  });

  final MailMessage message;
  final bool isLatest;
  final MailEmailAvatarResolver emailAvatars;
  final VoidCallback onReplyItem;

  @override
  State<_MailThreadItemCard> createState() => _MailThreadItemCardState();
}

class _MailThreadItemCardState extends State<_MailThreadItemCard> {
  late bool _expanded = widget.isLatest;

  void _showSenderProfileSheet(BuildContext context, String email) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  UiMailEmailAvatar(
                    email: email,
                    resolver: widget.emailAvatars,
                    radius: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Sender Profile', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.reply, color: cs.primary),
                title: const Text('Send Email'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onReplyItem();
                },
              ),
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: cs.primary),
                title: const Text('Send Chat Message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = widget.message;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_expanded ? 0 : 12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showSenderProfileSheet(context, m.fromAddr),
                    child: UiMailEmailAvatar(
                      email: m.fromAddr,
                      resolver: widget.emailAvatars,
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fromAddr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${'mail.to'.tr()}: ${m.toAddr}',
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatWhen(m.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _MailMessageBody(message: m),
            ),
            if (m.attachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('mail.attachments'.tr(), style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _MailAttachmentWrap(attachments: m.attachments),
                  ],
                ),
              ),
            ],
            if (m.error.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(m.error, style: TextStyle(color: cs.error)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatWhen(int ms) {
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat.MMMd().add_jm().format(dt);
  }
}

class _MailMessageBody extends StatelessWidget {
  const _MailMessageBody({required this.message});

  final MailMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return switch (message.bodyRenderKind) {
      MailBodyRenderKind.empty => Text('mail.emptyBody'.tr(), style: textStyle),
      MailBodyRenderKind.plainText => SelectableText(message.bodyText.trim(), style: textStyle),
      MailBodyRenderKind.markdown => _MailMarkdownBody(markdown: message.bodyText.trim()),
      MailBodyRenderKind.html => _MailHtmlBody(html: message.displayHtml),
    };
  }
}

Future<void> _confirmAndLaunchExternalUrl(BuildContext context, Uri uri) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.open_in_new_rounded, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Buka Tautan Luar'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anda akan meninggalkan Alien AI dan membuka tautan berikut di browser:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: SelectableText(
              uri.toString(),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pastikan domain tujuan aman sebelum memasukkan data atau kredensial.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.launch_rounded, size: 16),
          label: const Text('Buka Tautan'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MailMarkdownBody extends StatelessWidget {
  const _MailMarkdownBody({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.5,
      color: cs.onSurface,
    );
    return MarkdownBody(
      data: markdown,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null && href.trim().isNotEmpty) {
          final uri = Uri.tryParse(href.trim());
          if (uri != null) {
            unawaited(_confirmAndLaunchExternalUrl(context, uri));
          }
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: base,
        strong: base?.copyWith(fontWeight: FontWeight.w600),
        em: base?.copyWith(fontStyle: FontStyle.italic),
        listBullet: base,
        listIndent: 20,
        blockSpacing: 10,
        a: base?.copyWith(color: cs.primary, decoration: TextDecoration.underline),
        code: base?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: cs.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        h1: base?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        h2: base?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        h3: base?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        blockquote: base?.copyWith(color: cs.onSurfaceVariant),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: cs.outlineVariant, width: 3)),
        ),
      ),
    );
  }
}

class _MailHtmlBody extends StatefulWidget {
  const _MailHtmlBody({required this.html});

  final String html;

  @override
  State<_MailHtmlBody> createState() => _MailHtmlBodyState();
}

class _MailHtmlBodyState extends State<_MailHtmlBody> {
  double _height = 48;

  String _wrappedHtml(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = _mailCssColor(cs.onSurface);
    final bg = _mailCssColor(cs.surface);
    final link = _mailCssColor(cs.primary);
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data: cid:; style-src 'unsafe-inline'; font-src https: data:;">
<style>
  body { margin: 0; padding: 0; font-family: system-ui, -apple-system, sans-serif; font-size: 15px; line-height: 1.5; color: $fg; background: $bg; }
  img { max-width: 100%; height: auto; }
  a { color: $link; }
  blockquote { margin: 8px 0; padding-left: 12px; border-left: 3px solid rgba(127,127,127,0.35); }
</style>
</head>
<body>${widget.html}</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _wrappedHtml(context),
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: false,
          allowFileAccess: false,
          allowContentAccess: false,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
          transparentBackground: true,
          disableHorizontalScroll: true,
          supportZoom: false,
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
          disableVerticalScroll: true,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url?.uriValue;
          if (uri != null &&
              (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto')) {
            unawaited(_confirmAndLaunchExternalUrl(context, uri));
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.CANCEL;
        },
        onLoadStop: (controller, _) async {
          final h = await controller.getContentHeight();
          if (!mounted || h == null) return;
          final next = h.toDouble() + 4;
          if (next != _height) setState(() => _height = next);
        },
      ),
    );
  }
}

class _MailAttachmentWrap extends StatelessWidget {
  const _MailAttachmentWrap({required this.attachments});

  final List<MailAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final baseUrl = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in attachments)
          SizedBox(
            width: 96,
            child: _MailAttachmentChip(attachment: a, baseUrl: baseUrl),
          ),
      ],
    );
  }
}

class _MailAttachmentChip extends StatelessWidget {
  const _MailAttachmentChip({required this.attachment, required this.baseUrl});

  final MailAttachment attachment;
  final String baseUrl;

  Future<void> _open(BuildContext context) async {
    final path = attachment.path.trim();
    if (path.isEmpty) return;
    if (attachment.isImage) {
      await showMediaPreview(context, [path]);
      return;
    }
    final url = fileServeUrl(path, baseUrl: baseUrl);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => unawaited(_open(context)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                width: 80,
                child: attachment.isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: UiFsImage(
                          path: attachment.path,
                          baseUrl: baseUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _AttachIcon(
                        mime: attachment.mime,
                        cs: theme.colorScheme,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                attachment.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagedMailAttachmentChip extends StatelessWidget {
  const _StagedMailAttachmentChip({
    required this.item,
    required this.enabled,
    required this.onDelete,
    required this.onRetry,
  });

  final StagedMailAttachment item;
  final bool enabled;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final failed = item.error != null && item.error!.isNotEmpty;
    Widget? avatar;
    if (item.uploading) {
      avatar = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (failed) {
      avatar = Icon(Icons.error_outline, size: 18, color: cs.error);
    } else {
      avatar = Icon(
        item.isImage ? Icons.image_outlined : Icons.attach_file,
        size: 18,
      );
    }
    return InputChip(
      label: Text(item.name, overflow: TextOverflow.ellipsis),
      avatar: avatar,
      onDeleted: enabled ? onDelete : null,
      onPressed: failed && enabled ? onRetry : null,
    );
  }
}

class _MailComposeDialog extends StatefulWidget {
  const _MailComposeDialog({
    required this.chatConn,
    required this.mailboxes,
    required this.mailboxId,
    required this.fromAddress,
    this.onMailboxChanged,
    this.contacts = const [],
    required this.emailAvatars,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
    this.replyTo,
  });

  final ChatConn chatConn;
  final List<MailMailbox> mailboxes;
  final int mailboxId;
  final String fromAddress;
  final ValueChanged<MailMailbox>? onMailboxChanged;
  final List<EmailContact> contacts;
  final MailEmailAvatarResolver emailAvatars;
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;
  final MailMessage? replyTo;

  @override
  State<_MailComposeDialog> createState() => _MailComposeDialogState();
}

class _MailComposeDialogState extends State<_MailComposeDialog> {
  MailApi get _mailApi => MailApi(widget.chatConn);

  late final TextEditingController _toInputCtrl;
  late final TextEditingController _subjectCtrl;
  late final FocusNode _toFocusNode;
  late final FocusNode _subjectFocusNode;
  late final FocusNode _editorFocusNode;
  late final bool _isReply;

  late final EditorState _editorState;
  late final EditorScrollController _editorScrollController;

  late final MailStagedAttachmentsController _attachments;
  late int _activeMailboxId;
  late String _fromAddress;
  final List<String> _recipients = [];
  final List<String> _invalidTokens = [];
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attachments = MailStagedAttachmentsController(onChanged: () {
      if (mounted) setState(() {});
    });
    _recipients.addAll(_parseMailToAddresses(widget.initialTo ?? ''));
    _toInputCtrl = TextEditingController();
    _toInputCtrl.addListener(_onToInputChanged);
    _subjectCtrl = TextEditingController(text: widget.initialSubject ?? '');
    _toFocusNode = FocusNode();
    _subjectFocusNode = FocusNode();
    _editorFocusNode = FocusNode();
    _isReply = widget.replyTo != null;
    _activeMailboxId = widget.mailboxId;
    _fromAddress = widget.fromAddress;
    _syncFromMailbox();

    final initialText = widget.initialBody ?? '';
    final doc = widget.replyTo != null
        ? _buildMailReplyDocument(widget.replyTo!)
        : initialText.trim().isNotEmpty
            ? markdownToDocument(initialText)
            : Document.blank(withInitialText: true);

    _editorState = EditorState(document: doc);
    _editorScrollController = EditorScrollController(
      editorState: _editorState,
      shrinkWrap: false,
    );

    if (_isReply) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_placeReplyCaret()));
    } else {
      _ensureEditorSelectionOnFocus(_editorState, _editorFocusNode);
    }
  }

  Future<void> _placeReplyCaret() async {
    if (!mounted) return;
    final replyParagraph = _editorState.document.root.children
        .where((n) => n.type == ParagraphBlockKeys.type)
        .firstOrNull;
    if (replyParagraph == null) return;
    await _editorState.updateSelectionWithReason(
      Selection.collapsed(Position(path: replyParagraph.path, offset: 0)),
      reason: SelectionUpdateReason.uiEvent,
    );
    _editorFocusNode.requestFocus();
  }

  void _syncFromMailbox() {
    final mb = widget.mailboxes.where((m) => m.mailboxId == _activeMailboxId).firstOrNull;
    if (mb == null) return;
    _fromAddress = mb.address;
  }

  void _onToInputChanged() {
    _commitDelimiterTokens(_toInputCtrl.text);
    if (mounted) setState(() {});
  }

  void _commitDelimiterTokens(String value) {
    final delimiters = RegExp(r'[,;\n]');
    if (!delimiters.hasMatch(value)) return;
    final parts = value.split(delimiters);
    for (var i = 0; i < parts.length - 1; i++) {
      _commitToken(parts[i]);
    }
    final remainder = parts.last;
    _toInputCtrl.value = TextEditingValue(
      text: remainder,
      selection: TextSelection.collapsed(offset: remainder.length),
    );
  }

  void _commitToken(String raw) {
    final token = raw.trim();
    if (token.isEmpty) return;
    if (_looksLikeEmail(token)) {
      _addRecipient(token);
    } else {
      _addInvalidToken(token);
    }
  }

  void _addRecipient(String email) {
    final trimmed = email.trim();
    final lower = trimmed.toLowerCase();
    if (!_recipients.any((e) => e.toLowerCase() == lower)) {
      _recipients.add(trimmed);
      _invalidTokens.removeWhere((t) => t.toLowerCase() == lower);
    }
  }

  void _addInvalidToken(String token) {
    final trimmed = token.trim();
    final lower = trimmed.toLowerCase();
    if (_recipients.any((e) => e.toLowerCase() == lower)) return;
    if (!_invalidTokens.any((t) => t.toLowerCase() == lower)) {
      _invalidTokens.add(trimmed);
    }
  }

  void _removeRecipient(String email) {
    setState(() {
      _recipients.removeWhere((e) => e.toLowerCase() == email.toLowerCase());
    });
  }

  void _removeInvalidToken(String token) {
    setState(() {
      _invalidTokens.removeWhere((t) => t.toLowerCase() == token.toLowerCase());
    });
  }

  void _commitPendingToInput() {
    final pending = _toInputCtrl.text.trim();
    if (pending.isNotEmpty) {
      _commitToken(pending);
    }
    _toInputCtrl.clear();
  }

  void _onToSubmitted(String value) {
    _commitToken(value);
    _toInputCtrl.clear();
    setState(() {});
    _subjectFocusNode.requestFocus();
  }

  Future<void> _showFromMailboxPicker() async {
    final writable = widget.mailboxes.where((m) => m.canWrite).toList();
    if (writable.length <= 1) return;
    final picked = await showModalBottomSheet<MailMailbox>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.outgoing_mail, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'mail.from'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final mb in writable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: mb.mailboxId == _activeMailboxId
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: cs.primary,
                        child: Icon(
                          mb.kind == MailMailboxKind.site ? Icons.storefront_outlined : Icons.email,
                          color: cs.onPrimary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        mb.displayLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: mb.mailboxId == _activeMailboxId ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(mb.address),
                      trailing: mb.mailboxId == _activeMailboxId
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(mb),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || picked.mailboxId == _activeMailboxId) return;
    setState(() {
      _activeMailboxId = picked.mailboxId;
      _syncFromMailbox();
    });
    widget.onMailboxChanged?.call(picked);
  }

  @override
  void dispose() {
    _toInputCtrl.removeListener(_onToInputChanged);
    _toInputCtrl.dispose();
    _subjectCtrl.dispose();
    _toFocusNode.dispose();
    _subjectFocusNode.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  Future<void> _openContactPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<EmailContact>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _UiEmailContactPickerSheet(
        contacts: widget.contacts,
        emailAvatars: widget.emailAvatars,
      ),
    );
    if (picked != null) {
      setState(() => _addRecipient(picked.email));
    }
  }

  Future<void> _pickAttachments() async {
    if (_attachments.items.length >= mailStagedAttachmentMaxCount) return;
    try {
      final tooLarge = await _attachments.pickAndStage(context: context);
      if (!mounted) return;
      setState(() {
        _error = tooLarge != null
            ? 'mail.attachmentTooLarge'.tr(namedArgs: {'name': tooLarge})
            : null;
      });
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      setState(() => _error = uiFriendlyError(e));
    }
  }

  Future<bool> _confirmEmptySend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('mail.confirmEmptySendTitle'.tr()),
        content: Text('mail.confirmEmptySendBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('mail.send'.tr()),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _send() async {
    if (!_attachments.canSend) return;
    _commitPendingToInput();
    if (_recipients.isEmpty) {
      setState(() => _error = 'mail.invalidTo'.tr());
      return;
    }
    final subject = _subjectCtrl.text.trim();
    final bodyMarkdown = documentToMarkdown(_editorState.document).trim();
    if (subject.isEmpty && bodyMarkdown.isEmpty) {
      final confirmed = await _confirmEmptySend();
      if (!confirmed || !mounted) return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await _mailApi.send(
        mailboxId: _activeMailboxId,
        toAddr: _recipients.join(', '),
        subject: subject,
        bodyText: bodyMarkdown,
        attachments: _attachments.readyAttachments(),
      );
      if (!mounted) return;
      if (sent.status == MailStatus.failed) {
        setState(() {
          _sending = false;
          _error = sent.error.isNotEmpty ? sent.error : 'mail.sendFailed'.tr();
        });
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e, st) {
      lError('$e\n$st');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final writableMailboxes = widget.mailboxes.where((m) => m.canWrite).length;
    final canSwitchFrom = writableMailboxes > 1 && !_sending;
    final hasRecipientTokens = _recipients.isNotEmpty || _invalidTokens.isNotEmpty;

    final content = FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InkWell(
              onTap: canSwitchFrom ? () => unawaited(_showFromMailboxPicker()) : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${'mail.from'.tr()}: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _fromAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canSwitchFrom) Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: RawAutocomplete<EmailContact>(
                      textEditingController: _toInputCtrl,
                      focusNode: _toFocusNode,
                      displayStringForOption: (option) => option.email,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return const Iterable<EmailContact>.empty();
                        }
                        return widget.contacts.where((c) =>
                            c.email.toLowerCase().contains(query) ||
                            c.name.toLowerCase().contains(query));
                      },
                      onSelected: (EmailContact selection) {
                        _addRecipient(selection.email);
                        _toInputCtrl.clear();
                        setState(() {});
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final email in _recipients)
                              InputChip(
                                label: Text(
                                  email,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                avatar: UiMailEmailAvatar(
                                  email: email,
                                  resolver: widget.emailAvatars,
                                  radius: 10,
                                ),
                                backgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                visualDensity: VisualDensity.compact,
                                onDeleted: _sending ? null : () => _removeRecipient(email),
                                deleteIconColor: cs.onSecondaryContainer,
                              ),
                            for (final token in _invalidTokens)
                              InputChip(
                                label: Text(
                                  token,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                avatar: Icon(Icons.error_outline, size: 16, color: cs.onErrorContainer),
                                backgroundColor: cs.errorContainer.withValues(alpha: 0.75),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                visualDensity: VisualDensity.compact,
                                onDeleted: _sending ? null : () => _removeInvalidToken(token),
                                deleteIconColor: cs.onErrorContainer,
                              ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: hasRecipientTokens ? 120 : 200,
                              ),
                              child: IntrinsicWidth(
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: hasRecipientTokens ? 'mail.addRecipient'.tr() : 'mail.toHint'.tr(),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  ),
                                  enabled: !_sending,
                                  onSubmitted: (value) {
                                    onFieldSubmitted();
                                    _onToSubmitted(value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final c = options.elementAt(i);
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      leading: UiMailEmailAvatar(
                                        email: c.email,
                                        hintUrl: c.avatarUrl,
                                        resolver: widget.emailAvatars,
                                        radius: 14,
                                      ),
                                      title: Text(c.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(c.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: c.source == 'app'
                                              ? cs.secondaryContainer
                                              : cs.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c.source == 'app' ? 'App Contact' : 'Recent',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                                        ),
                                      ),
                                      onTap: () => onSelected(c),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.contacts_outlined, size: 20),
                  tooltip: 'Select Contact',
                  onPressed: _sending ? null : () => _openContactPicker(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: TextField(
                controller: _subjectCtrl,
                focusNode: _subjectFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'mail.subject'.tr(),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                enabled: !_sending,
                onSubmitted: (_) => _editorFocusNode.requestFocus(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: AppFlowyEditor(
                  editorState: _editorState,
                  editorScrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                  autoFocus: _isReply,
                  editorStyle: EditorStyle.mobile(
                    padding: const EdgeInsets.all(4),
                    cursorColor: cs.primary,
                    selectionColor: cs.primary.withValues(alpha: 0.25),
                    textStyleConfiguration: TextStyleConfiguration(
                      text: TextStyle(fontSize: 15, height: 1.4, color: cs.onSurface),
                      bold: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.bold, color: cs.onSurface),
                      italic: TextStyle(fontSize: 15, height: 1.4, fontStyle: FontStyle.italic, color: cs.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'mail.attach'.tr(),
                  onPressed: _sending ||
                          _attachments.items.length >= mailStagedAttachmentMaxCount ||
                          _attachments.anyUploading
                      ? null
                      : () => unawaited(_pickAttachments()),
                ),
                Expanded(
                  child: _attachments.items.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < _attachments.items.length; i++)
                              _StagedMailAttachmentChip(
                                item: _attachments.items[i],
                                enabled: !_sending,
                                onDelete: () => _attachments.removeAt(i),
                                onRetry: () => unawaited(_attachments.retryAt(i)),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _sending ? null : () => Navigator.of(context).pop(false),
              ),
              Expanded(
                child: Text(
                  'mail.compose'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
                        ),
                        onPressed: _sending || !_attachments.canSend ? null : _send,
                        icon: const Icon(Icons.send, size: 20),
                        tooltip: 'mail.send'.tr(),
                      ),
              ),
            ],
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _UiEmailContactPickerSheet extends StatefulWidget {
  const _UiEmailContactPickerSheet({
    required this.contacts,
    required this.emailAvatars,
  });

  final List<EmailContact> contacts;
  final MailEmailAvatarResolver emailAvatars;

  @override
  State<_UiEmailContactPickerSheet> createState() => _UiEmailContactPickerSheetState();
}

class _UiEmailContactPickerSheetState extends State<_UiEmailContactPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filtered = widget.contacts.where((c) {
      if (_query.isEmpty) return true;
      return c.name.toLowerCase().contains(_query) || c.email.toLowerCase().contains(_query);
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.contacts, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Contact',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: UiInputDecoration.of(
                context,
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No contacts found', style: theme.textTheme.bodyMedium),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: UiMailEmailAvatar(
                            email: c.email,
                            hintUrl: c.avatarUrl,
                            resolver: widget.emailAvatars,
                            radius: 20,
                          ),
                          title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.email),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.source == 'app' ? cs.secondaryContainer : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.source == 'app' ? 'App Contact' : 'Recent Email',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon shown inside non-image attachment thumbnails, picking a relevant icon
/// based on MIME type.
class _AttachIcon extends StatelessWidget {
  const _AttachIcon({required this.mime, required this.cs});

  final String mime;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (mime == 'application/pdf') {
      icon = Icons.picture_as_pdf_outlined;
    } else if (mime.startsWith('video/')) {
      icon = Icons.videocam_outlined;
    } else if (mime.startsWith('audio/')) {
      icon = Icons.audiotrack_outlined;
    } else if (mime.contains('zip') || mime.contains('rar') || mime.contains('tar')) {
      icon = Icons.folder_zip_outlined;
    } else if (mime.startsWith('text/')) {
      icon = Icons.description_outlined;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    return Center(
      child: Icon(icon, size: 32, color: cs.onSurfaceVariant),
    );
  }
}

/// A small pill badge showing `current / limit` with a tooltip that includes
/// the plan limit info and a "Contact us" message.
class _SubscriberLimitBadge extends StatelessWidget {
  const _SubscriberLimitBadge({
    required this.current,
    required this.limit,
    required this.compact,
  });

  final int current;
  final int limit;
  /// [compact] = tiny badge for the sidebar; false = slightly larger for the header.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = (current / limit).clamp(0.0, 1.0);

    // Color shifts from primary ΓåÆ warning ΓåÆ error as usage grows
    final Color badgeColor;
    final Color onBadge;
    if (ratio >= 1.0) {
      badgeColor = cs.errorContainer;
      onBadge = cs.onErrorContainer;
    } else if (ratio >= 0.8) {
      badgeColor = Color.lerp(cs.tertiaryContainer, cs.errorContainer, (ratio - 0.8) / 0.2)!;
      onBadge = cs.onTertiaryContainer;
    } else {
      badgeColor = cs.surfaceContainerHigh;
      onBadge = cs.onSurfaceVariant;
    }

    final text = compact ? '$current/$limit' : '$current / $limit subscribers';

    return Tooltip(
      preferBelow: true,
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: 'Subscriber limit: $current / $limit\n',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: 'Contact us to request more limit.'),
        ],
      ),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 1 : 3,
        ),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: onBadge,
          ),
        ),
      ),
    );
  }
}

/// A label/value row used in confirmation dialogs.
class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
