import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _border = Color(0xFF27272A);

class UiSiteAttendanceMyClock extends StatefulWidget {
  const UiSiteAttendanceMyClock({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteAttendanceMyClock> createState() => _UiSiteAttendanceMyClockState();
}

class _UiSiteAttendanceMyClockState extends State<UiSiteAttendanceMyClock> {
  var _loading = true;
  var _busy = false;
  String? _error;
  SitePresenceStaffContext? _ctx;
  final _records = <SitePresenceRecord>[];
  String _shiftId = '';

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctx = await widget.api.presenceStaffContext(widget.siteIid);
      final records = await widget.api.presenceRecordList(widget.siteIid, limit: 30);
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _records
          ..clear()
          ..addAll(records);
        if (_shiftId.isEmpty && ctx.workShiftIds.isNotEmpty) {
          _shiftId = ctx.workShiftIds.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clockIn() async {
    setState(() => _busy = true);
    try {
      await widget.api.presenceClockIn(widget.siteIid, shiftId: _shiftId);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clockOut() async {
    setState(() => _busy = true);
    try {
      await widget.api.presenceClockOut(widget.siteIid);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
      );
    }

    final ctx = _ctx;
    if (_error != null && ctx == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
        ),
      );
    }

    final canIn = ctx?.canClockIn ?? false;
    final canOut = ctx?.canClockOut ?? false;
    final shiftIds = ctx?.workShiftIds ?? const <String>[];

    final subtitle = ctx?.message.isNotEmpty == true
        ? ctx!.message
        : 'Clock-in is optional. Use it only when your site tracks attendance.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          title: 'My clock',
          subtitle: subtitle,
          icon: Icons.fingerprint_outlined,
        ),
        const SizedBox(height: 8),
        if (shiftIds.length > 1) ...[
          DropdownButtonFormField<String>(
            initialValue: shiftIds.contains(_shiftId) ? _shiftId : shiftIds.first,
            decoration: const InputDecoration(labelText: 'Work schedule', isDense: true),
            items: [
              for (final id in shiftIds)
                DropdownMenuItem(value: id, child: Text(id, style: const TextStyle(fontSize: 13))),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    if (v != null) setState(() => _shiftId = v);
                  },
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy || !canIn ? null : _clockIn,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Clock in'),
                style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1C)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy || !canOut ? null : _clockOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Clock out'),
                style: OutlinedButton.styleFrom(foregroundColor: _text, side: const BorderSide(color: _border)),
              ),
            ),
          ],
        ),
        if (ctx != null && ctx.openClockInMs > Int64.ZERO) ...[
          const SizedBox(height: 12),
          Text(
            'Clocked in since ${_formatMs(ctx.openClockInMs.toInt())}',
            style: const TextStyle(fontSize: 12, color: _accent),
          ),
        ],
        const SizedBox(height: 24),
        const Text('RECENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _muted)),
        const SizedBox(height: 8),
        if (_records.isEmpty)
          const Text('No records yet', style: TextStyle(fontSize: 12, color: _muted))
        else
          for (final r in _records) _recordTile(r),
      ],
    );
  }

  Widget _recordTile(SitePresenceRecord r) {
    final kind = r.kind == 'clock_out' ? 'Out' : 'In';
    final when = _formatMs(r.atMs.toInt());
    final extra = r.kind == 'clock_out' && r.workDurationMin > 0 ? ' · ${r.workDurationMin} min' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _border.withValues(alpha: 0.85)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(kind, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kind == 'In' ? _accent : _muted)),
              const SizedBox(width: 10),
              Expanded(child: Text(when, style: const TextStyle(fontSize: 12, color: _text))),
              if (extra.isNotEmpty) Text(extra, style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
