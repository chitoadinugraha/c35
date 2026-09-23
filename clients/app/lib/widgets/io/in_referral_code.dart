import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const specialReferralCodes = {'CHITOKERENSEKALI9999'};

bool referralCodeIsSpecial(String code) => specialReferralCodes.contains(referralCodeNorm(code));

bool referralCodeReadyForCheck(String code) {
  final norm = referralCodeNorm(code);
  if (norm.isEmpty) return false;
  if (referralCodeIsSpecial(norm)) return true;
  return norm.length >= 8;
}

int referralCodeDisplayMaxLen() => referralCodeNormMaxLen + (referralCodeNormMaxLen ~/ referralCodeGroupLen) - 1;

/// Live-validated referral code field with debounce and issuer preview.
class InReferralCode extends StatefulWidget {
  const InReferralCode({
    super.key,
    this.autofocus = false,
    this.labelText = 'Referral Code',
    this.initial = '',
    this.onChanged,
  });

  final bool autofocus;
  final String labelText;
  final String initial;
  final void Function(InReferralCodeState state)? onChanged;

  @override
  State<InReferralCode> createState() => InReferralCodeState();
}

class InReferralCodeState extends State<InReferralCode> {
  late final TextEditingController _codeCtrl;
  Timer? _debounce;
  var _checking = false;
  var _invalid = false;
  var _connError = false;
  var _codeValid = false;
  var _allowShortId = false;
  var _issuerName = '';
  var _issuerPic = '';

  String get codeNorm => referralCodeNorm(_codeCtrl.text);
  bool get codeValid => _codeValid;
  bool get isSpecial => referralCodeIsSpecial(codeNorm);
  bool get allowsShortId => _allowShortId || isSpecial;
  bool get checking => _checking;
  String get issuerName => _issuerName;
  String get issuerPic => _issuerPic;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initial);
    if (widget.initial.isNotEmpty) {
      _checkCode(referralCodeNorm(widget.initial));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void clear() {
    _debounce?.cancel();
    _codeCtrl.clear();
    setState(() {
      _checking = false;
      _invalid = false;
      _connError = false;
      _codeValid = false;
      _allowShortId = false;
      _issuerName = '';
      _issuerPic = '';
    });
    widget.onChanged?.call(this);
  }

  void _notify() => widget.onChanged?.call(this);

  void _onCodeChanged(String raw) {
    final norm = referralCodeNorm(raw);
    final formatted = referralCodeFormat(norm);
    if (_codeCtrl.text != formatted) {
      _codeCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _checkCode(norm));
  }

  Future<void> _checkCode(String norm) async {
    if (!referralCodeReadyForCheck(norm)) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _invalid = false;
        _connError = false;
        _codeValid = false;
        _allowShortId = false;
        _issuerName = '';
        _issuerPic = '';
      });
      _notify();
      return;
    }
    if (referralCodeIsSpecial(norm)) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _invalid = false;
        _connError = false;
        _codeValid = true;
        _allowShortId = true;
        _issuerName = 'Alien AI';
        _issuerPic = '';
      });
      _notify();
      return;
    }
    setState(() {
      _checking = true;
      _invalid = false;
      _connError = false;
      _codeValid = false;
      _allowShortId = false;
      _issuerName = '';
      _issuerPic = '';
    });
    _notify();
    try {
      final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/v1/auth/referral/lookup').replace(queryParameters: {'code': norm});
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _connError = true;
          _checking = false;
        });
        _notify();
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['valid'] == true) {
        setState(() {
          _codeValid = true;
          _allowShortId = data['allow_short_id'] == true;
          _issuerName = '${data['issuer_name'] ?? ''}';
          _issuerPic = '${data['issuer_pic'] ?? ''}';
          _checking = false;
        });
      } else {
        setState(() {
          _invalid = true;
          _checking = false;
        });
      }
      _notify();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connError = true;
        _checking = false;
      });
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = const Color(0xFF71717A);
    const errorColor = Color(0xFFF87171);
    const successColor = Color(0xFF34D399);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeCtrl,
          autofocus: widget.autofocus,
          decoration: UiInputDecoration.of(
            context,
            labelText: widget.labelText,
            hintText: referralCodeHint,
            suffixIcon: _codeCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: clear,
                    icon: const Icon(Icons.clear, size: 18),
                  ),
          ),
          maxLength: referralCodeDisplayMaxLen(),
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w500),
          onChanged: _onCodeChanged,
        ),
        if (_checking)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399))),
                const SizedBox(width: 8),
                Text('Checking code…', style: theme.textTheme.labelSmall?.copyWith(color: muted)),
              ],
            ),
          ),
        if (_connError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Network error checking referral code', style: theme.textTheme.labelSmall?.copyWith(color: errorColor)),
          ),
        if (_invalid && !_checking)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Invalid referral code', style: theme.textTheme.labelSmall?.copyWith(color: errorColor)),
          ),
        if (!_checking && !_invalid && !_connError && _codeValid && _issuerName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                children: [
                  UiUserAvatar(name: _issuerName, pic: _issuerPic, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Referred by', style: theme.textTheme.labelSmall?.copyWith(color: muted, fontSize: 11)),
                        Text(_issuerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: successColor, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
