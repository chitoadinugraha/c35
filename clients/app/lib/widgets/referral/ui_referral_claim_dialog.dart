import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/widgets/io/in_referral_code.dart';
import 'package:flutter/material.dart';

class UiReferralClaimDialog extends StatefulWidget {
  const UiReferralClaimDialog({super.key, required this.auth});

  final AuthService auth;

  static Future<bool?> show(BuildContext context, {required AuthService auth}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UiReferralClaimDialog(auth: auth),
    );
  }

  @override
  State<UiReferralClaimDialog> createState() => _UiReferralClaimDialogState();
}

class _UiReferralClaimDialogState extends State<UiReferralClaimDialog> {
  var _code = '';
  var _codeValid = false;
  var _busy = false;
  String? _error;

  void _onReferralChanged(InReferralCodeState s) {
    setState(() {
      _code = s.codeNorm;
      _codeValid = s.codeValid;
      _error = null;
    });
  }

  Future<void> _claim() async {
    if (!_codeValid || _code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.auth.claimReferral(_code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed Rp ${(res['bonus_idr'] ?? 10000).toInt()} bonus from ${res['issuer_name'] ?? 'Referrer'}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = uiAuthError(e);
          _busy = false;
        });
      }
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.auth.dismissReferralPrompt();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF34D399), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Do you have a Referral Code?',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Get Rp. 10.000 if you enter the referral code.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            InReferralCode(
              autofocus: true,
              labelText: 'Referral Code',
              onChanged: _onReferralChanged,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _skip,
          child: const Text("I don't have one", style: TextStyle(color: Color(0xFF71717A))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF34D399),
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF27272A),
            disabledForegroundColor: const Color(0xFF52525B),
          ),
          onPressed: (_codeValid && !_busy) ? _claim : null,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Claim Rp 10.000', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
