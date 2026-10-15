import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_row_visit.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _cardBg = Color(0xFF18181B);
const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _hoverBg = Color(0xFF27272A);
const _accent = Color(0xFF34D399);
const _cardW = 320.0;

class UiStaffSiteManageAction {
  const UiStaffSiteManageAction({
    required this.onEdit,
    this.onPos,
  });

  final VoidCallback onEdit;
  final VoidCallback? onPos;
}

Future<void> uiStaffSiteManageCardShow({
  required BuildContext context,
  required ChatConn chatConn,
  required SiteRow row,
  required UiStaffSiteManageAction action,
}) =>
    uiDialogShow<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => _UiStaffSiteManageCardDialog(hostContext: context, chatConn: chatConn, row: row, action: action),
    );

class _UiStaffSiteManageCardDialog extends StatefulWidget {
  const _UiStaffSiteManageCardDialog({
    required this.hostContext,
    required this.chatConn,
    required this.row,
    required this.action,
  });

  final BuildContext hostContext;
  final ChatConn chatConn;
  final SiteRow row;
  final UiStaffSiteManageAction action;

  @override
  State<_UiStaffSiteManageCardDialog> createState() => _UiStaffSiteManageCardDialogState();
}

class _UiStaffSiteManageCardDialogState extends State<_UiStaffSiteManageCardDialog> {
  late final SiteApi _api = SiteApi(widget.chatConn);
  var _loading = true;
  String? _error;
  SiteEditorCaps _caps = const SiteEditorCaps();
  var _pageViews7d = 0;
  var _uniqueVisitors7d = 0;
  var _activeMs7d = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteIid = widget.row.siteIid.toInt();
      final config = await _api.configGet(siteIid);
      final caps = SiteEditorCaps.parse(config.capabilitiesJson);
      var pv = 0;
      var uv = 0;
      var active = 0;
      try {
        final now = DateTime.now();
        final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        final to = DateTime(now.year, now.month, now.day);
        final res = await _api.queryRun(
          queryId: 'visitor.summary',
          siteIids: [siteIid],
          params: {
            'day_from': _dayKey(from),
            'day_to': _dayKey(to),
          },
        );
        for (final q in res.rows) {
          pv += int.tryParse(q.cells['page_views'] ?? '') ?? 0;
          uv += int.tryParse(q.cells['unique_visitors'] ?? '') ?? 0;
          active += int.tryParse(q.cells['active_duration_ms'] ?? '') ?? 0;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _caps = caps;
        _pageViews7d = pv;
        _uniqueVisitors7d = uv;
        _activeMs7d = active;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _closeThen(VoidCallback? fn) {
    Navigator.pop(context);
    fn?.call();
  }

  String get _slug => widget.row.alienId.isNotEmpty ? widget.row.alienId : widget.row.siteIid.toString();

  String get _title => widget.row.name.isNotEmpty ? widget.row.name : _slug;

  bool get _posEnabled => _caps.commerce;

  List<({String label, IconData icon})> get _features {
    final out = <({String label, IconData icon})>[];
    if (_caps.commerce) out.add((label: 'Store', icon: Icons.storefront_outlined));
    if (_caps.booking) out.add((label: 'Reservations', icon: Icons.event_available_outlined));
    if (_caps.queue) out.add((label: 'Queue', icon: Icons.people_alt_outlined));
    if (_caps.attendance) out.add((label: 'Attendance', icon: Icons.fingerprint_outlined));
    if (_caps.orderFulfillment) out.add((label: 'Orders', icon: Icons.receipt_long_outlined));
    return out;
  }

  String _formatActiveDuration(int ms) {
    if (ms <= 0) return '0 min';
    final min = (ms / 60000).round();
    if (min < 60) return '$min min';
    final h = min / 60;
    return h >= 10 ? '${h.round()} hr' : '${h.toStringAsFixed(1)} hr';
  }

  @override
  Widget build(BuildContext context) {
    final published = widget.row.publishedVersionId.isNotEmpty;
    return Center(
      child: Material(
        color: _cardBg,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
        child: SizedBox(
          width: _cardW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  children: [
                    _siteAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('$siteUrlPrefix$_slug', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _statusChip(published ? 'Published' : 'Draft', published ? _accent : _muted),
                              if (widget.row.isArchived) _statusChip('Archived', const Color(0xFFEF4444)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20, color: _muted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Visitors (7 days)', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _statRow(Icons.people_outline_rounded, 'Unique visitors', '$_uniqueVisitors7d'),
                      const SizedBox(height: 6),
                      _statRow(Icons.visibility_outlined, 'Page views', '$_pageViews7d'),
                      const SizedBox(height: 6),
                      _statRow(Icons.timer_outlined, 'Active time', _formatActiveDuration(_activeMs7d)),
                    ],
                  ),
                ),
                if (_features.isNotEmpty) ...[
                  const Divider(height: 1, color: _border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Features', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _features.map((f) => _featureChip(f.label, f.icon)).toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const Divider(height: 1, color: _border),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        label: 'Visit',
                        icon: Icons.open_in_new_rounded,
                        onTap: () => _closeThen(() => unawaited(siteRowVisit(widget.hostContext, widget.row))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _actionBtn(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: () => _closeThen(widget.action.onEdit),
                      ),
                    ),
                    if (_posEnabled && widget.action.onPos != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionBtn(
                          label: 'POS',
                          icon: Icons.point_of_sale_outlined,
                          onTap: () => _closeThen(widget.action.onPos),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _siteAvatar() {
    final pic = widget.row.pic.trim();
    final fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: _hoverBg, borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.language_outlined, size: 20, color: _muted),
    );
    if (pic.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: UiImg(src: pic, width: 40, height: 40, fit: BoxFit.cover, fallback: fallback),
    );
  }

  Widget _statusChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  Widget _statRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))),
          Text(value, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _featureChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: _hoverBg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _actionBtn({required String label, required IconData icon, required VoidCallback onTap}) => Material(
        color: _hoverBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: _text),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
