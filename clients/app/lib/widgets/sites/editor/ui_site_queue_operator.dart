import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_queue_board.dart';
import 'package:alienai_c35/c/site/site_queue_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';
const _muted = Color(0xFF71717A);

class UiSiteQueueOperator extends StatefulWidget {
  const UiSiteQueueOperator({
    super.key,
    required this.api,
    required this.siteIid,
    required this.queue,
    this.onQueueRowChanged,
  });

  final SiteApi api;
  final int siteIid;
  final SiteQueue queue;
  final ValueChanged<SiteQueue>? onQueueRowChanged;

  @override
  State<UiSiteQueueOperator> createState() => _UiSiteQueueOperatorState();
}

class _UiSiteQueueOperatorState extends State<UiSiteQueueOperator> {
  var _loading = true;
  var _busy = false;
  String? _error;
  SiteQueueBoardSnapshot? _board;
  SiteQueueBoardTicket? _selected;
  Timer? _poll;

  int get _queueId => widget.queue.queueId.toInt();

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => unawaited(_refresh(silent: true)));
  }

  @override
  void didUpdateWidget(covariant UiSiteQueueOperator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queue.queueId != widget.queue.queueId) {
      _selected = null;
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final board = await widget.api.queueBoard(widget.siteIid, _queueId);
      if (!mounted) return;
      setState(() {
        _board = board;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = uiFriendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _callNext() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final serving = await widget.api.queueCallNext(widget.siteIid, queueId: _queueId);
      final next = widget.queue.clone()..servingTicketNo = serving;
      widget.onQueueRowChanged?.call(next);
      await _refresh(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Now serving ticket $serving')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String status) async {
    final ticket = _selected;
    if (ticket == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.queueTicketSetStatus(
        widget.siteIid,
        queueId: _queueId,
        ticketId: ticket.ticketId,
        status: status,
      );
      _selected = null;
      await _refresh(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _labelForTicket(SiteQueueBoardTicket t) {
    if (t.displayLabel.isNotEmpty) return t.displayLabel;
    return siteQueueTicketPreview(widget.queue, ticketNo: t.ticketNo);
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    final servingNo = board?.servingTicketNo ?? widget.queue.servingTicketNo;
    final servingLabel = board != null && board.servingLabel.isNotEmpty
        ? board.servingLabel
        : siteQueueTicketPreview(widget.queue, ticketNo: servingNo);
    final waiting = board?.waiting ?? const <SiteQueueBoardTicket>[];
    final called = board?.called ?? const <SiteQueueBoardTicket>[];
    final boardRpcReady = board != null && (waiting.isNotEmpty || called.isNotEmpty);

    if (_loading && board == null) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }

    return UiSiteEditorFormScroll(
      children: [
        UiSiteEditorFormSection(
          title: 'Now serving',
          children: [
            Text(
              servingLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: siteEditorFormAccent,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ticket #$servingNo · Last issued #${board?.lastTicketNo ?? widget.queue.lastTicketNo}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _callNext,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Call next'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ),
        if (!boardRpcReady)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Live waiting list sync is not available yet. Call next still advances the serving number on this counter.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
            ),
          ),
        UiSiteEditorFormSection(
          title: 'Waiting',
          children: [
            if (waiting.isEmpty)
              const Text('No tickets waiting.', style: TextStyle(color: _muted, fontSize: 13))
            else
              ...waiting.map((t) => _ticketRow(t, selected: _selected?.ticketId == t.ticketId)),
          ],
        ),
        if (called.isNotEmpty)
          UiSiteEditorFormSection(
            title: 'Called',
            children: called.map((t) => _ticketRow(t, selected: _selected?.ticketId == t.ticketId)).toList(),
          ),
        UiSiteEditorFormSection(
          title: 'Selected ticket',
          children: [
            Text(
              _selected == null ? 'Tap a ticket to skip or mark done.' : _labelForTicket(_selected!),
              style: const TextStyle(color: siteEditorFormText, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selected == null || _busy ? null : () => unawaited(_setStatus('skipped')),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected == null || _busy ? null : () => unawaited(_setStatus('done')),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : () => unawaited(_refresh()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ),
      ],
    );
  }

  Widget _ticketRow(SiteQueueBoardTicket t, {required bool selected}) {
    final subtitle = [t.guestName, t.guestPhone].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? siteEditorFormAccent.withValues(alpha: 0.12) : siteEditorFieldFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? siteEditorFormAccent : siteEditorFieldBorder),
        ),
        child: InkWell(
          onTap: () => setState(() => _selected = t),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_labelForTicket(t), style: const TextStyle(color: siteEditorFormText, fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
                    ],
                  ),
                ),
                Text(t.status, style: const TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
