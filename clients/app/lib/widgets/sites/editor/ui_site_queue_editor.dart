import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_listener.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSiteQueueEditor extends StatefulWidget {
  const UiSiteQueueEditor({super.key, required this.api, required this.siteIid, this.queueEnabled = true});

  final SiteApi api;
  final int siteIid;
  final bool queueEnabled;

  @override
  State<UiSiteQueueEditor> createState() => _UiSiteQueueEditorState();
}

class _UiSiteQueueEditorState extends State<UiSiteQueueEditor> with SiteEditorCatalogListener {
  var _loading = true;
  var _busy = false;
  String? _error;
  SiteQueue? _queue;
  var _loadScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    unawaited(_reload());
  }

  @override
  void onEditorCatalogUpdated(SiteEditorCatalogCache catalog) {
    if (!mounted) return;
    setState(() {
      _queue = catalog.primaryQueue ?? widget.api.queueNew(widget.siteIid);
      _loading = false;
      if (catalog.warmError != null && _queue == null) {
        _error = uiFriendlyError(catalog.warmError!);
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (await ensureEditorCatalog()) return;
      final queues = await widget.api.queueList(widget.siteIid);
      editorCatalog?.setQueues(queues);
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
      final next = q.clone()..servingTicketNo = serving;
      setState(() => _queue = next);
      editorCatalog?.upsertQueue(next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.queueEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Queue is off for this site. Turn it on under Settings → Capabilities to use take-a-number on the storefront.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }
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
