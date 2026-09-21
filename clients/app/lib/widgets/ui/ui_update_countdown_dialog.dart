import 'dart:async';
import 'package:flutter/material.dart';

class UiUpdateCountdownDialog extends StatefulWidget {
  const UiUpdateCountdownDialog({
    super.key,
    required this.version,
    required this.onConfirm,
    this.onCancel,
    this.seconds = 10,
  });

  final String version;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final int seconds;

  @override
  State<UiUpdateCountdownDialog> createState() => _UiUpdateCountdownDialogState();
}

class _UiUpdateCountdownDialogState extends State<UiUpdateCountdownDialog> {
  late int _secondsLeft;
  Timer? _timer;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _apply();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _apply() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    widget.onConfirm();
  }

  void _cancel() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel();
      },
      child: Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.system_update_alt_rounded, color: Color(0xFF34D399), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Update Ready', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(widget.version.isNotEmpty ? widget.version : 'New version', style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('The app has been idle. Restarting to apply the update in $_secondsLeft seconds…', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.45)),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.seconds > 0 ? _secondsLeft / widget.seconds : 0.0,
                    backgroundColor: const Color(0xFF27272A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(onPressed: _cancel, style: TextButton.styleFrom(foregroundColor: const Color(0xFFA1A1AA)), child: const Text('Cancel / Later')),
                    FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                      child: const Text('Restart Now', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
