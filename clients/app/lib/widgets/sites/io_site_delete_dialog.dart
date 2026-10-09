import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_slide_confirm.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _dangerColor = Color(0xFFEF4444);
const _border = Color(0xFF27272A);
const _bg = Color(0xFF18181B);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);

/// Confirm permanent site deletion — retype handle + slide + countdown + delete.
Future<bool> siteDeleteConfirmShow(
  BuildContext context, {
  required SiteStore store,
  required SiteRow row,
}) async {
  if (isPlatformSiteAlienId(row.alienId)) return false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => IoSiteDeleteDialog(store: store, row: row),
  );
  return result == true;
}

enum _DeletePhase { input, countdown, ready, deleting }

class IoSiteDeleteDialog extends StatefulWidget {
  const IoSiteDeleteDialog({
    super.key,
    required this.store,
    required this.row,
  });

  final SiteStore store;
  final SiteRow row;

  @override
  State<IoSiteDeleteDialog> createState() => _IoSiteDeleteDialogState();
}

class _IoSiteDeleteDialogState extends State<IoSiteDeleteDialog> {
  late final TextEditingController _confirmCtrl = TextEditingController();
  var _phase = _DeletePhase.input;
  var _countdown = 3;
  var _error = '';
  Timer? _countdownTimer;

  String get _expectedId {
    final handle = widget.row.alienId.trim();
    if (handle.isNotEmpty) return handle;
    return '${widget.row.siteIid}';
  }

  String get _displayPath => '$siteUrlPrefix$_expectedId';

  bool get _idMatches => _confirmCtrl.text.trim().toLowerCase() == _expectedId.toLowerCase();

  bool get _busy => _phase == _DeletePhase.countdown || _phase == _DeletePhase.deleting;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onSlideConfirm() {
    if (_phase != _DeletePhase.input || !_idMatches) return;
    setState(() {
      _phase = _DeletePhase.countdown;
      _countdown = 3;
      _error = '';
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _phase = _DeletePhase.ready);
        return;
      }
      setState(() => _countdown--);
    });
  }

  Future<void> _delete() async {
    if (_phase != _DeletePhase.ready) return;
    setState(() {
      _phase = _DeletePhase.deleting;
      _error = '';
    });
    try {
      final id = widget.row.siteIid.toString();
      await widget.store.deletePut(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      lError('site delete error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _DeletePhase.ready;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.row.name.trim().isNotEmpty ? widget.row.name.trim() : _expectedId;

    return AlertDialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border),
      ),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Delete site?',
              style: TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          uiIconButton(
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, color: _muted, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(color: _title, fontSize: 13, height: 1.45),
                children: [
                  const TextSpan(text: 'Delete site "'),
                  TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  const TextSpan(
                    text: '" permanently? Published pages, products, and settings for this site will be removed. This cannot be undone.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: const TextStyle(color: _muted, fontSize: 12),
                children: [
                  const TextSpan(text: 'To confirm, type '),
                  TextSpan(
                    text: _displayPath,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _dangerColor),
                  ),
                  const TextSpan(text: ' below:'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              enabled: _phase == _DeletePhase.input,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: _title, fontSize: 13),
              onChanged: (_) => setState(() {}),
              decoration: UiInputDecoration.of(
                context,
                floatingLabel: false,
                hintText: _expectedId,
                prefixText: siteUrlPrefix,
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: _dangerColor, fontSize: 12)),
            ],
            ...switch (_phase) {
              _DeletePhase.input when _idMatches => [
                  const SizedBox(height: 20),
                  UiSlideConfirm(
                    enabled: true,
                    color: _dangerColor,
                    label: 'Slide to confirm deletion',
                    doneLabel: 'Confirmed',
                    onConfirm: _onSlideConfirm,
                  ),
                ],
              _DeletePhase.countdown => [
                  const SizedBox(height: 24),
                  const Text(
                    'Deleting in…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_countdown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 44,
                      color: _dangerColor,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              _DeletePhase.ready => [
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _delete,
                    style: FilledButton.styleFrom(
                      backgroundColor: _dangerColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    child: const Text('Permanently delete site'),
                  ),
                ],
              _DeletePhase.deleting => [
                  const SizedBox(height: 20),
                  const SizedBox(
                    height: 50,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _dangerColor),
                      ),
                    ),
                  ),
                ],
              _ => const [],
            },
          ],
        ),
      ),
    );
  }
}
