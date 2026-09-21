import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
final _pairCodeRe = RegExp(r'^[A-Z0-9]{10}$');

String devicePairCodeNormalize(String raw) => raw.toUpperCase().replaceAll('-', '');

String? devicePairCodeError(String raw) {
  final code = devicePairCodeNormalize(raw);
  if (code.isEmpty) return 'Enter a pairing code';
  if (code.length != 10) return 'Code must be 10 characters';
  if (!_pairCodeRe.hasMatch(code)) return 'Use letters A–Z and digits 0–9 only';
  return null;
}

Future<String?> inDevicePairAsk(BuildContext context) => showDialog<String>(
      context: context,
      builder: (ctx) => const _DevicePairDialog(),
    );

class _DevicePairDialog extends StatefulWidget {
  const _DevicePairDialog();

  @override
  State<_DevicePairDialog> createState() => _DevicePairDialogState();
}

class _DevicePairDialogState extends State<_DevicePairDialog> {
  late final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pair() {
    final err = devicePairCodeError(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, devicePairCodeNormalize(_ctrl.text));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _border)),
        title: const Text('Pair device', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 18)),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, letterSpacing: 2),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_DevicePairCodeFormatter()],
            decoration: InputDecoration(
              hintText: 'XXXXX-XXXXX',
              hintStyle: const TextStyle(color: _muted, letterSpacing: 2),
              errorText: _error,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34D399))),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _pair(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _pair,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: const Text('Pair'),
          ),
        ],
      );
}

class _DevicePairCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final capped = raw.length > 10 ? raw.substring(0, 10) : raw;
    final formatted = capped.length <= 5 ? capped : '${capped.substring(0, 5)}-${capped.substring(5)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
