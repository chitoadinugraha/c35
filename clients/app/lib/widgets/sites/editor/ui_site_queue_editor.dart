import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSiteQueueEditor extends StatefulWidget {
  const UiSiteQueueEditor({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteQueueEditor> createState() => _UiSiteQueueEditorState();
}

class _UiSiteQueueEditorState extends State<UiSiteQueueEditor> {
  var _loading = true;
  var _busy = false;
  String? _error;
  SiteQueue? _queue;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final queues = await widget.api.queueList(widget.siteIid);
      if (!mounted) return;
      setState(() {
        _queue = queues.isNotEmpty ? queues.first : widget.api.queueNew(widget.siteIid);
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

  Future<void> _advance() async {
    final q = _queue;
    if (q == null) return;
    setState(() => _busy = true);
    try {
      final serving = await widget.api.queueAdvanceServing(widget.siteIid, queueId: q.queueId.toInt());
      if (!mounted) return;
      setState(() => _queue = q.clone()..servingTicketNo = serving);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }
    final q = _queue!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(q.name.isNotEmpty ? q.name : 'Queue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Now serving: ${q.servingTicketNo} · Last ticket: ${q.lastTicketNo}', style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _advance,
            icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.skip_next),
            label: const Text('Call next'),
          ),
        ],
      ),
    );
  }
}
