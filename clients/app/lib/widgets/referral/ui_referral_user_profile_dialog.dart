import 'package:alienai_c35/c/billing/billing_admin_adjust.dart';
import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/referral/referral_period.dart';
import 'package:alienai_c35/c/referral/referral_stats_api.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_commission_breakdown.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_date_range_sheet.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_admin_adjust_history_sheet.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_admin_dialogs.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_wallet_adjust_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

typedef ReferralProfileResult = ({ReferralTreeNode? node, bool reloadTree});

Future<ReferralProfileResult?> referralUserProfileDialog(
  BuildContext context, {
  required ReferralConn conn,
  required ReferralTreeNode node,
  bool isSelf = false,
  bool viewerIsRoot = false,
  ReferralTreeNode? referrer,
  ValueChanged<ReferralTreeNode>? onOpenReferrer,
  VoidCallback? onFocus,
}) =>
    showDialog<ReferralProfileResult>(
      context: context,
      builder: (ctx) => _ReferralUserProfileDialog(
        conn: conn,
        node: node,
        isSelf: isSelf,
        viewerIsRoot: viewerIsRoot,
        referrer: referrer,
        onOpenReferrer: onOpenReferrer,
        onFocus: onFocus,
      ),
    );

class _ReferralPalette {
  static const bg = Color(0xFF18181B);
  static const section = Color(0xFF27272A);
  static const border = Color(0xFF3F3F46);
  static const text = Color(0xFFF4F4F5);
  static const muted = Color(0xFFA1A1AA);
  static const accent = Color(0xFF22C55E);
  static const error = Color(0xFFF87171);
}

ReferralTreeNode _patchNode(
  ReferralTreeNode n, {
  String? name,
  String? email,
  String? handle,
  String? avatarUrl,
  int? referredBy,
  bool clearReferredBy = false,
}) {
  final out = ReferralTreeNode()..mergeFromMessage(n);
  if (name != null) out.name = name;
  if (email != null) out.email = email;
  if (handle != null) out.handle = handle;
  if (avatarUrl != null) out.avatarUrl = avatarUrl;
  if (clearReferredBy) {
    out.referredBy = Int64.ZERO;
  } else if (referredBy != null) {
    out.referredBy = Int64(referredBy);
  }
  return out;
}

String? _handleValidate(String raw) {
  var id = raw.trim().toLowerCase();
  if (id.startsWith('@')) id = id.substring(1);
  if (id.isEmpty) return 'Handle required';
  if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(id)) return 'Use letters, numbers, _ or -';
  return null;
}

class _ReferralUserProfileDialog extends StatefulWidget {
  const _ReferralUserProfileDialog({
    required this.conn,
    required this.node,
    this.isSelf = false,
    this.viewerIsRoot = false,
    this.referrer,
    this.onOpenReferrer,
    this.onFocus,
  });

  final ReferralConn conn;
  final ReferralTreeNode node;
  final bool isSelf;
  final bool viewerIsRoot;
  final ReferralTreeNode? referrer;
  final ValueChanged<ReferralTreeNode>? onOpenReferrer;
  final VoidCallback? onFocus;

  @override
  State<_ReferralUserProfileDialog> createState() => _ReferralUserProfileDialogState();
}

class _ReferralUserProfileDialogState extends State<_ReferralUserProfileDialog> {
  late ReferralTreeNode _node;
  ReferralTreeNode? _referrer;
  late final AdminApi _admin;
  var _busy = false;
  var _reloadTree = false;
  var _statsBusy = false;
  ReferralUserStatsRow? _stats;
  ReferralUserWalletSnapshot? _wallet;
  var _authEmail = '';
  var _authPhone = '';
  late ReferralPeriodRange _colARange = referralPeriodRange(ReferralPeriodPreset.mtd);
  late ReferralPeriodRange _colBRange = referralPeriodRange(ReferralPeriodPreset.lastMonth);
  late String _colALabel = 'This Month';
  late String _colBLabel = 'Last Month';

  @override
  void initState() {
    super.initState();
    _node = widget.node;
    _referrer = widget.referrer;
    _admin = AdminApi(widget.conn);
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_statsBusy) return;
    setState(() => _statsBusy = true);
    try {
      final stats = await referralUserStatsGet(
        widget.conn,
        subjectUid: _node.id,
        colA: _colARange,
        colB: _colBRange,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _wallet = stats.wallet;
        _authEmail = stats.authEmail;
        _authPhone = stats.authPhone;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stats = null;
        _wallet = null;
        _authEmail = '';
        _authPhone = '';
      });
    } finally {
      if (mounted) setState(() => _statsBusy = false);
    }
  }

  Future<void> _adjustWallet({required String kind, required bool credit}) async {
    if (!_canAdjust) return;
    final currency = _wallet?.billingCurrency.isNotEmpty == true ? _wallet!.billingCurrency : 'IDR';
    final res = await referralWalletAdjustDialog(
      context,
      conn: widget.conn,
      subjectUid: _node.id.toInt(),
      subjectName: _node.name,
      kind: kind,
      credit: credit,
      currency: currency,
    );
    if (res == null || !mounted) return;
    setState(() {
      _wallet = ReferralUserWalletSnapshot(
        balanceIdr: res.balanceIdr,
        balanceUsd: res.balanceUsd,
        commissionAvailableIdr: res.commissionAvailableIdr,
        commissionAvailableUsd: res.commissionAvailableUsd,
        billingCurrency: res.currency,
      );
    });
    await _loadStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${credit ? 'Added' : 'Removed'} ${kind == billingAdminAdjustKindCommission ? 'commission' : 'balance'}'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openAdjustHistory() async {
    if (!_canAdjust) return;
    await referralAdminAdjustHistorySheet(context, conn: widget.conn, subjectUid: _node.id.toInt());
  }

  String _walletAmountLabel({required bool commission}) {
    final w = _wallet;
    if (w == null) return _statsBusy ? '…' : '—';
    final cur = w.billingCurrency.isNotEmpty ? w.billingCurrency : 'IDR';
    if (commission) return referralCommissionAmountLabel(cur, w.commissionAvailableUsd, w.commissionAvailableIdr);
    return referralCommissionAmountLabel(cur, w.balanceUsd, w.balanceIdr);
  }

  Future<void> _pickColumnRange({required bool colA}) async {
    final initial = colA ? _colARange : _colBRange;
    final picked = await referralDateRangeSheet(context, initial: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (colA) {
        _colARange = picked;
        _colALabel = referralPeriodShortLabel(picked);
      } else {
        _colBRange = picked;
        _colBLabel = referralPeriodShortLabel(picked);
      }
    });
    await _loadStats();
  }

  bool get _canEdit => widget.viewerIsRoot && !_busy;
  bool get _canAdjust => (Session.instance.isRoot || Session.instance.globalRoles.contains('director')) && !_busy;
  bool get _canEditReferrer => _canEdit && !referralNodeIsRoot(_node);
  bool get _canViewContact => Session.instance.isRoot || Session.instance.globalRoles.contains('director');

  String get _platformLabel {
    final h = _node.handle.trim();
    if (h.isNotEmpty) return profileAlienAddress(h.replaceFirst('@', ''));
    return '';
  }

  String? get _loginEmailLabel {
    if (!_canViewContact) return null;
    final email = _authEmail.trim().isNotEmpty ? _authEmail.trim() : _node.email.trim();
    if (email.isEmpty || email.endsWith('@$profileAlienDomain')) return null;
    return email;
  }

  String? get _loginPhoneLabel {
    if (!_canViewContact) return null;
    final phone = _authPhone.trim();
    return phone.isEmpty ? null : phone;
  }

  List<String> get _roles => [
        if (referralNodeIsRoot(_node)) 'Root',
        ..._node.globalRoles.where((r) => r != 'root').map(referralGlobalRoleLabel),
      ];

  String get _referredLabel => _referrer?.name.trim().isNotEmpty == true
      ? _referrer!.name
      : _node.parentId == 0
          ? 'Not set'
          : 'Unknown';

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiReferralError(e, fallback: 'Something went wrong. Please try again.')), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName() async {
    if (!_canEdit) return;
    final trimmed = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextPromptDialog(
        title: 'Rename user',
        label: 'Name',
        initial: _node.name,
        textInputAction: TextInputAction.done,
        onSubmit: (v) => v.trim().isNotEmpty ? v.trim() : null,
      ),
    );
    if (trimmed == null || trimmed == _node.name) return;
    await _run(() async {
      await _admin.userPut(targetId: _node.id, name: trimmed);
      if (!mounted) return;
      setState(() {
        _reloadTree = true;
        _node = _patchNode(_node, name: trimmed);
      });
    });
  }

  Future<void> _editEmail() async {
    if (!_canEdit) return;
    final trimmed = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextPromptDialog(
        title: 'Change email',
        label: 'Login email',
        initial: _loginEmailLabel ?? _node.email,
        keyboardType: TextInputType.emailAddress,
        onSubmit: (v) {
          final t = v.trim().toLowerCase();
          return t.isNotEmpty ? t : null;
        },
      ),
    );
    if (trimmed == null || trimmed == _node.email) return;
    await _run(() async {
      final ok = await _admin.authEmailAvailable(trimmed, excludeId: _node.id);
      if (!ok) throw Exception('Email already registered');
      await _admin.userPut(targetId: _node.id, authEmail: trimmed);
      if (!mounted) return;
      setState(() {
        _reloadTree = true;
        _node = _patchNode(_node, email: trimmed);
      });
    });
  }

  Future<void> _editHandle() async {
    if (!_canEdit) return;
    final initial = _node.handle.trim().replaceFirst('@', '').toLowerCase();
    final trimmed = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextPromptDialog(
        title: 'Change Alien ID',
        label: 'Alien ID',
        initial: initial,
        onSubmit: (v) {
          final err = _handleValidate(v);
          if (err != null) return null;
          var id = v.trim().toLowerCase();
          if (id.startsWith('@')) id = id.substring(1);
          return id;
        },
      ),
    );
    if (trimmed == null || trimmed == initial) return;
    await _run(() async {
      final available = await _admin.handleAvailable(trimmed, excludeId: _node.id);
      if (!available) throw Exception('Handle already taken');
      await _admin.userPut(targetId: _node.id, handle: trimmed);
      if (!mounted) return;
      setState(() {
        _reloadTree = true;
        _node = _patchNode(_node, handle: trimmed.startsWith('@') ? trimmed : '@$trimmed');
      });
    });
  }

  Future<void> _changePic() async {
    if (!_canEdit) return;
    final picked = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false);
    final file = picked?.firstOrNull;
    if (file == null) return;
    await _run(() async {
      final res = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (res == null) throw Exception('Upload failed');
      await _admin.userPut(targetId: _node.id, avatarUrl: res.url);
      if (!mounted) return;
      setState(() {
        _reloadTree = true;
        _node = _patchNode(_node, avatarUrl: res.url);
      });
    });
  }

  Future<void> _setReferredBy() async {
    if (!_canEditReferrer) return;
    final hit = await referralAdminReferredByDialog(context, conn: widget.conn, target: _node);
    if (hit == null || !mounted) return;
    setState(() {
      _reloadTree = true;
      _node = _patchNode(_node, referredBy: hit.identityId.toInt());
      _referrer = ReferralTreeNode(
        identityId: hit.identityId,
        name: hit.name,
        email: hit.email,
        handle: hit.handle,
        avatarUrl: hit.avatarUrl,
      );
    });
  }

  Future<void> _clearReferredBy() async {
    if (!_canEditReferrer || _node.parentId == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ReferralPalette.bg,
        title: const Text('Clear referred by', style: TextStyle(color: _ReferralPalette.text)),
        content: Text('Remove referrer for ${_node.name}?', style: const TextStyle(color: _ReferralPalette.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _admin.userPut(targetId: _node.id, clearReferredBy: true);
      if (!mounted) return;
      setState(() {
        _reloadTree = true;
        _node = _patchNode(_node, clearReferredBy: true);
        _referrer = null;
      });
    });
  }

  Future<void> _onEditAction(String action) async {
    switch (action) {
      case 'name':
        await _editName();
      case 'email':
        await _editEmail();
      case 'handle':
        await _editHandle();
      case 'pic':
        await _changePic();
      case 'set_referrer':
        await _setReferredBy();
      case 'clear_referrer':
        await _clearReferredBy();
    }
  }

  Future<void> _openReferrer() async {
    final ref = _referrer;
    if (ref == null || widget.onOpenReferrer == null) return;
    Navigator.pop(context, (node: _node, reloadTree: _reloadTree));
    widget.onOpenReferrer!(ref);
  }

  void _close() => Navigator.pop(context, (node: _node, reloadTree: _reloadTree));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _close();
        },
        child: Dialog(
          backgroundColor: _ReferralPalette.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _ReferralPalette.border)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.sizeOf(context).height * 0.88),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 2, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiUserAvatar(name: _node.name, handle: _node.handle, pic: _node.avatarUrl, size: 56, showBorder: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_node.name, style: const TextStyle(color: _ReferralPalette.text, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                            if (widget.isSelf) const Padding(padding: EdgeInsets.only(top: 2), child: Text('(you)', style: TextStyle(color: _ReferralPalette.muted, fontSize: 12))),
                            if (_platformLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(_platformLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ReferralPalette.muted, fontSize: 12)),
                            ],
                            if (_loginEmailLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(_loginEmailLabel!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ReferralPalette.muted, fontSize: 12)),
                            ],
                            if (_loginPhoneLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(_loginPhoneLabel!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ReferralPalette.muted, fontSize: 12)),
                            ],
                            if (_node.isBanned) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: _ReferralPalette.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: const Text('Banned', style: TextStyle(color: _ReferralPalette.error, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_canEdit)
                            PopupMenuButton<String>(
                              tooltip: uiPopupMenuTooltipText('Edit user'),
                              enabled: !_busy,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              color: _ReferralPalette.bg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _ReferralPalette.border)),
                              onSelected: _onEditAction,
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'name', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.badge_outlined, size: 20, color: _ReferralPalette.muted), title: Text('Change name'), dense: true)),
                                const PopupMenuItem(value: 'email', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.mail_outline, size: 20, color: _ReferralPalette.muted), title: Text('Change email'), dense: true)),
                                const PopupMenuItem(value: 'handle', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.alternate_email_outlined, size: 20, color: _ReferralPalette.muted), title: Text('Change Alien ID'), dense: true)),
                                const PopupMenuItem(value: 'pic', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.photo_outlined, size: 20, color: _ReferralPalette.muted), title: Text('Change picture'), dense: true)),
                                if (_canEditReferrer) ...[
                                  const PopupMenuItem(value: 'set_referrer', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.person_add_alt_1_outlined, size: 20, color: _ReferralPalette.muted), title: Text('Set referred by'), dense: true)),
                                  if (_node.parentId != 0)
                                    const PopupMenuItem(value: 'clear_referrer', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.person_remove_outlined, size: 20, color: _ReferralPalette.muted), title: Text('Clear referred by'), dense: true)),
                                ],
                              ],
                              child: uiPopupMenuChild(
                                tooltip: 'Edit user',
                                child: const Icon(Icons.edit_outlined, size: 20, color: _ReferralPalette.muted),
                              ),
                            ),
                          if (widget.onFocus != null)
                            uiIconButton(
                              tooltip: 'Center in tree',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: _busy
                                  ? null
                                  : () {
                                      Navigator.pop(context, (node: _node, reloadTree: _reloadTree));
                                      widget.onFocus!();
                                    },
                              icon: const Icon(Icons.my_location_rounded, size: 20, color: _ReferralPalette.muted),
                            ),
                          const SizedBox(width: 4),
                          uiIconButton(
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: _busy ? null : _close,
                            icon: const Icon(Icons.close, size: 20, color: _ReferralPalette.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_node.parentId != 0 || _referrer != null || _canEditReferrer) ...[
                          _ProfileSection(
                            title: 'Referred by',
                            showTrailing: _referrer != null || _canEditReferrer,
                            onTap: _referrer != null && !_busy ? _openReferrer : null,
                            child: Row(
                              children: [
                                if (_referrer != null)
                                  UiUserAvatar(name: _referrer!.name, handle: _referrer!.handle, pic: _referrer!.avatarUrl, size: 28, showBorder: false)
                                else
                                  const Icon(Icons.person_outline, size: 20, color: _ReferralPalette.muted),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_referredLabel, style: const TextStyle(color: _ReferralPalette.text, fontSize: 14, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_roles.isNotEmpty) ...[
                          _ProfileSection(
                            title: 'Roles',
                            child: Wrap(spacing: 5, runSpacing: 5, children: _roles.map((r) => _RoleChip(label: r)).toList()),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_wallet != null || _statsBusy) ...[
                          _ProfileWalletSection(
                            balanceLabel: _walletAmountLabel(commission: false),
                            commissionLabel: _walletAmountLabel(commission: true),
                            loading: _statsBusy,
                            canAdjust: _canAdjust,
                            onAdjustBalance: (credit) => _adjustWallet(kind: billingAdminAdjustKindBalance, credit: credit),
                            onAdjustCommission: (credit) => _adjustWallet(kind: billingAdminAdjustKindCommission, credit: credit),
                            onHistory: _canAdjust ? _openAdjustHistory : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _ProfileStatsSection(
                          totalReferrals: _node.childCount,
                          colALabel: _colALabel,
                          colBLabel: _colBLabel,
                          colA: _stats?.colA,
                          colB: _stats?.colB,
                          loading: _statsBusy,
                          onColATap: () => _pickColumnRange(colA: true),
                          onColBTap: () => _pickColumnRange(colA: false),
                        ),
                        if (widget.viewerIsRoot) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => referralCommissionSimulateDialog(
                                      context,
                                      conn: widget.conn,
                                      subjectUid: _node.id,
                                      subjectName: _node.name,
                                      subjectPic: _node.avatarUrl,
                                    ),
                            icon: const Icon(Icons.calculate_outlined, size: 16),
                            label: const Text('Simulate commission'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ReferralPalette.accent,
                              side: const BorderSide(color: _ReferralPalette.border),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _ReferralPalette.accent))),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child, this.onTap, this.showTrailing = false});

  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _ReferralPalette.section.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ReferralPalette.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: _ReferralPalette.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3))),
              if (onTap != null || showTrailing) const Icon(Icons.chevron_right, size: 18, color: _ReferralPalette.muted),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: body));
  }
}

class _ProfileWalletSection extends StatelessWidget {
  const _ProfileWalletSection({
    required this.balanceLabel,
    required this.commissionLabel,
    required this.loading,
    required this.canAdjust,
    required this.onAdjustBalance,
    required this.onAdjustCommission,
    this.onHistory,
  });

  final String balanceLabel;
  final String commissionLabel;
  final bool loading;
  final bool canAdjust;
  final ValueChanged<bool> onAdjustBalance;
  final ValueChanged<bool> onAdjustCommission;
  final VoidCallback? onHistory;

  Widget _adjustButtons(ValueChanged<bool> onTap) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          uiIconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: loading ? null : () => onTap(false),
            icon: const Icon(Icons.remove_circle_outline, size: 18, color: _ReferralPalette.error),
          ),
          const SizedBox(width: 2),
          uiIconButton(
            tooltip: 'Add',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: loading ? null : () => onTap(true),
            icon: const Icon(Icons.add_circle_outline, size: 18, color: _ReferralPalette.accent),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => _StatsCard(
        title: 'Wallet',
        icon: Icons.account_balance_wallet_outlined,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Expanded(flex: 4, child: Text('Balance', style: TextStyle(color: _ReferralPalette.muted, fontSize: 12, fontWeight: FontWeight.w500))),
                  Expanded(
                    flex: 3,
                    child: Text(balanceLabel, textAlign: TextAlign.right, style: const TextStyle(color: _ReferralPalette.text, fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                  Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: canAdjust ? _adjustButtons(onAdjustBalance) : const SizedBox.shrink())),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Expanded(flex: 4, child: Text('Commission', style: TextStyle(color: _ReferralPalette.muted, fontSize: 12, fontWeight: FontWeight.w500))),
                  Expanded(
                    flex: 3,
                    child: Text(commissionLabel, textAlign: TextAlign.right, style: const TextStyle(color: _ReferralPalette.text, fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                  Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: canAdjust ? _adjustButtons(onAdjustCommission) : const SizedBox.shrink())),
                ],
              ),
            ),
            if (onHistory != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: loading ? null : onHistory, child: const Text('Adjustment history')),
              ),
            ],
          ],
        ),
      );
}

class _ProfileStatsSection extends StatelessWidget {
  const _ProfileStatsSection({
    required this.totalReferrals,
    required this.colALabel,
    required this.colBLabel,
    required this.colA,
    required this.colB,
    required this.loading,
    required this.onColATap,
    required this.onColBTap,
  });

  final int totalReferrals;
  final String colALabel;
  final String colBLabel;
  final ReferralUserStatColumn? colA;
  final ReferralUserStatColumn? colB;
  final bool loading;
  final VoidCallback onColATap;
  final VoidCallback onColBTap;

  String _commission(ReferralUserStatColumn? col) {
    if (col == null) return '—';
    if (col.commissionIdr > 0) return 'Rp ${uiFmtGroupedInt(col.commissionIdr.round())}';
    if (col.commissionUsd > 0) return referralUsdLabel(col.commissionUsd);
    return '—';
  }

  String _tokens(ReferralUserStatColumn? col, {required bool alien}) {
    if (col == null) return '—';
    final n = alien ? col.tokensAlien.toInt() : col.tokensApi.toInt();
    return n > 0 ? uiFmtGroupedInt(n) : '—';
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsCard(
            title: 'Referrals',
            icon: Icons.people_outline,
            child: Column(
              children: [
                _StatsHeader(colALabel: colALabel, colBLabel: colBLabel, onColATap: onColATap, onColBTap: onColBTap),
                const SizedBox(height: 6),
                _StatsRow(label: 'Count', colA: '${colA?.referralCount ?? (loading ? '…' : '0')}', colB: '${colB?.referralCount ?? (loading ? '…' : '0')}'),
                _StatsRow(label: 'Commission', colA: loading ? '…' : _commission(colA), colB: loading ? '…' : _commission(colB)),
                const Divider(height: 16, color: _ReferralPalette.border),
                _StatsRow(label: 'All time', colA: '$totalReferrals', colB: '', emphasize: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StatsCard(
            title: 'Token Used',
            icon: Icons.token_outlined,
            child: Column(
              children: [
                _StatsHeader(colALabel: colALabel, colBLabel: colBLabel, onColATap: onColATap, onColBTap: onColBTap),
                const SizedBox(height: 6),
                _StatsRow(label: 'Alien AI', colA: loading ? '…' : _tokens(colA, alien: true), colB: loading ? '…' : _tokens(colB, alien: true)),
                _StatsRow(label: 'API', colA: loading ? '…' : _tokens(colA, alien: false), colB: loading ? '…' : _tokens(colB, alien: false)),
              ],
            ),
          ),
        ],
      );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _ReferralPalette.section.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _ReferralPalette.border.withValues(alpha: 0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: _ReferralPalette.accent),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(color: _ReferralPalette.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.colALabel, required this.colBLabel, required this.onColATap, required this.onColBTap});

  final String colALabel;
  final String colBLabel;
  final VoidCallback onColATap;
  final VoidCallback onColBTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(flex: 4, child: SizedBox.shrink()),
          Expanded(
            flex: 3,
            child: _StatsHeaderCell(label: colALabel, onTap: onColATap),
          ),
          Expanded(
            flex: 3,
            child: _StatsHeaderCell(label: colBLabel, onTap: onColBTap),
          ),
        ],
      );
}

class _StatsHeaderCell extends StatelessWidget {
  const _StatsHeaderCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: const TextStyle(color: _ReferralPalette.accent, fontSize: 10, fontWeight: FontWeight.w700))),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 14, color: _ReferralPalette.accent),
            ],
          ),
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.label, required this.colA, required this.colB, this.emphasize = false});

  final String label;
  final String colA;
  final String colB;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: emphasize ? _ReferralPalette.text : _ReferralPalette.muted, fontSize: emphasize ? 13 : 12, fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500);
    final valueStyle = TextStyle(color: _ReferralPalette.text, fontSize: emphasize ? 13 : 12, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: style)),
          Expanded(flex: 3, child: Text(colA, textAlign: TextAlign.right, style: valueStyle)),
          Expanded(flex: 3, child: Text(colB, textAlign: TextAlign.right, style: valueStyle)),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _ReferralPalette.section, borderRadius: BorderRadius.circular(999), border: Border.all(color: _ReferralPalette.border)),
        child: Text(label, style: const TextStyle(color: _ReferralPalette.text, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.keyboardType,
    this.textInputAction,
    required this.onSubmit,
  });

  final String title;
  final String label;
  final String initial;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String value) onSubmit;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final result = widget.onSubmit(_ctrl.text);
    if (result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _ReferralPalette.bg,
        title: Text(widget.title, style: const TextStyle(color: _ReferralPalette.text)),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: const TextStyle(color: _ReferralPalette.text),
          decoration: UiInputDecoration.of(context, labelText: widget.label),
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}
