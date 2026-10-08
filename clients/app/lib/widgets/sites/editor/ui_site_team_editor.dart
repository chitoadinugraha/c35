import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_color.dart';
import 'package:alienai_c35/c/site/site_member.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/io_site_member_face_photos.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_schedule_preview.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

List<SiteScheduleSlot> _workShiftToSlots(SiteWorkShift shift) => [
      for (final s in shift.slots)
        SiteScheduleSlot(
          id: s.id.isEmpty ? '${shift.id}-${s.startDay}-${s.startMin}' : s.id,
          startDay: s.startDay,
          startMin: s.startMin,
          endDay: s.endDay,
          endMin: s.endMin,
        ),
    ];

String _grantId(SiteGrant g) => g.granteeIid.toString();

String _grantEmail(SiteGrant g) {
  if (g.granteeEmail.isNotEmpty) return g.granteeEmail;
  if (g.granteeAlienId.isNotEmpty) return '@${g.granteeAlienId}';
  return g.granteeIid.toString();
}

String _grantDisplayName(SiteGrant g) =>
    siteMemberDisplayName(displayName: g.granteeName, email: _grantEmail(g));

bool _grantIsOwner(SiteGrant g) => g.isOwner || siteMemberRoleWire(g.role) == siteMemberRoleOwner;

Future<bool> _confirmRoleChange(BuildContext context, SiteGrant grant, String role) async {
  if (role == siteMemberRoleWire(grant.role)) return false;
  final name = _grantDisplayName(grant);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Change role'),
      content: Text('Change $name from ${siteMemberRoleLabel(grant.role)} to ${siteMemberRoleLabel(role)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
      ],
    ),
  );
  return ok == true;
}

Future<bool> _confirmRemoveMember(BuildContext context, SiteGrant grant) async {
  final name = _grantDisplayName(grant);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove member'),
      content: Text('Remove $name from this site?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<bool> _confirmTransfer(BuildContext context, SiteGrant grant) async {
  final name = _grantDisplayName(grant);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Transfer ownership'),
      content: Text('Transfer site ownership to $name? You will become a Manager.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Transfer')),
      ],
    ),
  );
  return ok == true;
}

class UiSiteTeamEditor extends StatefulWidget {
  const UiSiteTeamEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    this.caps = const SiteEditorCaps(),
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
    this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final SiteEditorCaps caps;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final Future<void> Function()? onCapabilitiesSaved;

  @override
  State<UiSiteTeamEditor> createState() => _UiSiteTeamEditorState();
}

class _UiSiteTeamEditorState extends State<UiSiteTeamEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  List<SiteGrant> _grants = const [];
  List<SiteWorkShift> _shifts = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteTeamEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_reload());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && !_grants.any((g) => _grantId(g) == _selectedId)) _pickDefault();
  }

  Map<String, SiteGrant> get _byId => {for (final g in _grants) _grantId(g): g};

  String? get _firstId => _grants.isEmpty ? null : _grantId(_grants.first);

  String? get _activeId => widget.masterDetail ? (_selectedId ?? _firstId) : widget.detailId;

  void _pickDefault() {
    if (_grants.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || !_byId.containsKey(_selectedId)) _selectedId = _firstId;
      return;
    }
    if (widget.detailId != null && !_byId.containsKey(widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grants = await widget.api.grantList(widget.siteIid);
      List<SiteWorkShift> shifts = const [];
      try {
        shifts = await widget.api.workShiftList(widget.siteIid);
      } catch (_) {
        shifts = const [];
      }
      if (!mounted) return;
      setState(() {
        _grants = grants;
        _shifts = shifts;
        _loading = false;
      });
      _pickDefault();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = uiFriendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _snack(Object e) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
  }

  Future<void> _invite() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Invite member'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: UiInputDecoration.of(ctx, labelText: 'Email or @alien_id', hintText: 'name@example.com or @handle'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Invite')),
          ],
        );
      },
    );
    final v = raw?.trim() ?? '';
    if (v.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final startsAt = v.startsWith('@');
      final isEmail = !startsAt && v.contains('@');
      await widget.api.grantPut(
        widget.siteIid,
        granteeEmail: isEmail ? v : '',
        granteeAlienId: isEmail ? '' : (startsAt ? v.substring(1) : v),
        role: 'staff',
      );
      await widget.onCapabilitiesSaved?.call();
      await _reload();
      final alien = startsAt ? v.substring(1) : v;
      SiteGrant? match;
      for (final g in _grants) {
        if (isEmail && g.granteeEmail.toLowerCase() == v.toLowerCase()) {
          match = g;
          break;
        }
        if (!isEmail && g.granteeAlienId.toLowerCase() == alien.toLowerCase()) {
          match = g;
          break;
        }
      }
      match ??= _grants.isEmpty ? null : _grants.last;
      if (match != null) _select(_grantId(match));
    } catch (e) {
      await _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rolePut(SiteGrant grant, String role) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.grantPut(
        widget.siteIid,
        granteeIid: grant.granteeIid,
        role: role,
        workShiftIds: grant.workShiftIds.toList(),
      );
      await widget.onCapabilitiesSaved?.call();
      await _reload();
    } catch (e) {
      await _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shiftsPut(SiteGrant grant, List<String> workShiftIds) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.grantPut(
        widget.siteIid,
        granteeIid: grant.granteeIid,
        role: siteMemberRoleWire(grant.role),
        workShiftIds: workShiftIds,
      );
      await _reload();
    } catch (e) {
      await _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(SiteGrant grant) async {
    if (_busy || _grantIsOwner(grant)) return;
    if (!await _confirmRemoveMember(context, grant)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.grantDelete(widget.siteIid, grant.granteeIid.toInt());
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      await widget.onCapabilitiesSaved?.call();
      await _reload();
    } catch (e) {
      await _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transfer(SiteGrant grant) async {
    if (_busy || _grantIsOwner(grant)) return;
    if (!await _confirmTransfer(context, grant)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.transferOwnership(widget.siteIid, grant.granteeIid.toInt());
      await widget.onCapabilitiesSaved?.call();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ownership transferred')));
      }
    } catch (e) {
      await _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<SiteGrant> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _grants;
    return _grants.where((g) {
      final name = g.granteeName.toLowerCase();
      final email = g.granteeEmail.toLowerCase();
      final alien = g.granteeAlienId.toLowerCase();
      final role = siteMemberRoleLabel(g.role).toLowerCase();
      return name.contains(q) || email.contains(q) || alien.contains(q) || role.contains(q) || _grantId(g).contains(q);
    }).toList(growable: false);
  }

  Widget _listPane({required String? selectedId}) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search team',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _busy ? null : _invite,
          addBusy: _busy,
        ),
        if (_grants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              _grants.length == 1 ? '1 member' : '${_grants.length} members',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? UiEmptyState(
                  icon: Icons.group_outlined,
                  title: _search.trim().isEmpty ? 'No team members yet' : 'No matches',
                  subtitle: _search.trim().isEmpty ? 'Invite someone by email or @alien_id.' : 'Try a different search.',
                  actionHint: _search.trim().isEmpty ? 'Tap + to invite' : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final g = filtered[i];
                    final id = _grantId(g);
                    final active = selectedId == id;
                    final name = _grantDisplayName(g);
                    final email = _grantEmail(g);
                    final role = siteMemberRoleLabel(g.role);
                    final cs = Theme.of(context).colorScheme;
                    return Material(
                      color: active ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: active ? cs.primary.withValues(alpha: 0.25) : cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _select(id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                          child: Row(
                            children: [
                              UiUserAvatar(name: name, email: g.granteeEmail, handle: g.granteeAlienId, pic: g.granteeAvatarUrl, size: 36),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: active ? cs.onSurface : _text, fontSize: 13)),
                                    if (g.granteeName.trim().isNotEmpty && email != name)
                                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _muted)),
                                    Text(role, style: const TextStyle(fontSize: 12, color: _muted)),
                                  ],
                                ),
                              ),
                              if (!widget.masterDetail) Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detailPane(String id) {
    final grant = _byId[id];
    if (grant == null) {
      return const Center(child: Text('Member not found', style: TextStyle(color: _muted)));
    }
    return _MemberDetail(
      key: ValueKey(id),
      api: widget.api,
      siteIid: widget.siteIid,
      grant: grant,
      shifts: _shifts,
      attendanceEnabled: widget.caps.attendance,
      busy: _busy,
      onRoleChanged: (role) async {
        if (!await _confirmRoleChange(context, grant, role)) return;
        await _rolePut(grant, role);
      },
      onShiftsChanged: (ids) => _shiftsPut(grant, ids),
      onTransfer: () => _transfer(grant),
      onRemove: () => _remove(grant),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    if (_error != null && _grants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    final detailId = _activeId;
    final Widget body;
    if (widget.masterDetail && _grants.isNotEmpty) {
      final selected = detailId ?? _firstId!;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detailPane(selected)),
        ],
      );
    } else {
      body = widget.masterDetail || detailId == null ? _listPane(selectedId: detailId) : _detailPane(detailId);
    }

    if (_error == null || _error!.isEmpty) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0x33F87171),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _MemberDetail extends StatelessWidget {
  const _MemberDetail({
    super.key,
    required this.api,
    required this.siteIid,
    required this.grant,
    required this.shifts,
    required this.attendanceEnabled,
    required this.busy,
    required this.onRoleChanged,
    required this.onShiftsChanged,
    required this.onTransfer,
    required this.onRemove,
  });

  final SiteApi api;
  final int siteIid;
  final SiteGrant grant;
  final List<SiteWorkShift> shifts;
  final bool attendanceEnabled;
  final bool busy;
  final Future<void> Function(String role) onRoleChanged;
  final Future<void> Function(List<String> workShiftIds) onShiftsChanged;
  final VoidCallback onTransfer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = _grantIsOwner(grant);
    final role = siteMemberRoleWire(grant.role);
    final name = _grantDisplayName(grant);
    final email = _grantEmail(grant);
    final shiftIds = Set<String>.from(grant.workShiftIds);

    return UiSiteEditorFormScroll(
      children: [
        Row(
          children: [
            UiUserAvatar(name: name, email: grant.granteeEmail, handle: grant.granteeAlienId, pic: grant.granteeAvatarUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: _text)),
                  if (grant.granteeName.trim().isNotEmpty && email != name)
                    Text(email, style: const TextStyle(fontSize: 12, color: _muted)),
                  Text(siteMemberRoleLabel(grant.role), style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!isOwner)
          DropdownButtonFormField<String>(
            key: ValueKey('${_grantId(grant)}-$role'),
            initialValue: siteMemberRoles.any((r) => r.$1 == role) ? role : 'staff',
            decoration: UiInputDecoration.of(context, labelText: 'Role'),
            isExpanded: true,
            items: siteMemberRoles.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
            onChanged: busy
                ? null
                : (v) async {
                    if (v == null || v == role) return;
                    await onRoleChanged(v);
                  },
          ),
        if (!isOwner) const SizedBox(height: 20),
        UiSchedulePreview(
          entries: [
            for (var i = 0; i < shifts.length; i++)
              UiSchedulePreviewEntry(
                id: shifts[i].id,
                name: shifts[i].name,
                color: sitePaletteColorAt(i),
                slots: _workShiftToSlots(shifts[i]),
                enabled: shiftIds.contains(shifts[i].id),
              ),
          ],
          onToggle: busy || isOwner
              ? null
              : (shiftId) {
                  final next = Set<String>.from(shiftIds);
                  if (next.contains(shiftId)) {
                    next.remove(shiftId);
                  } else {
                    next.add(shiftId);
                  }
                  unawaited(onShiftsChanged(next.toList()));
                },
        ),
        if (attendanceEnabled) ...[
          const SizedBox(height: 24),
          IoSiteMemberFacePhotos(
            api: api,
            siteIid: siteIid,
            granteeIid: grant.granteeIid.toInt(),
            attendanceEnabled: attendanceEnabled,
          ),
        ],
        if (!isOwner) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: busy ? null : onTransfer,
            icon: Icon(Icons.swap_horiz, size: 18, color: Colors.amber.shade700),
            label: Text('Transfer ownership', style: TextStyle(color: Colors.amber.shade700)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Remove member'),
            style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          ),
        ],
        if (busy) ...[
          const SizedBox(height: 16),
          const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ],
    );
  }
}
