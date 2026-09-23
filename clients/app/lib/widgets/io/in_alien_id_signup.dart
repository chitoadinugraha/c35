import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/widgets/io/in_referral_code.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

String alienIdSignupNorm(String input) =>
    input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');

class InAlienIdSignup extends StatefulWidget {
  const InAlienIdSignup({
    super.key,
    this.controller,
    this.initial = '',
    this.onChanged,
    this.onValidChanged,
    this.referralCode = '',
  });

  final TextEditingController? controller;
  final String initial;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidChanged;
  final String referralCode;

  @override
  State<InAlienIdSignup> createState() => _InAlienIdSignupState();
}

class _InAlienIdSignupState extends State<InAlienIdSignup> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  Timer? _debounce;
  var _loading = false;
  bool? _available;
  var _checkError = false;
  String? _checkErrorMessage;
  bool? _previousValid;

  bool get _specialReferral => referralCodeIsSpecial(widget.referralCode);
  int get _minLen => _specialReferral ? 1 : 7;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController(text: alienIdSignupNorm(widget.initial));
    _controller.addListener(_onTextChanged);
    if (widget.initial.isNotEmpty) {
      _checkAvailability(alienIdSignupNorm(widget.initial));
    }
  }

  @override
  void didUpdateWidget(InAlienIdSignup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.referralCode != oldWidget.referralCode) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _checkAvailability(alienIdSignupNorm(_controller.text).trim());
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _notifyValid(bool valid) {
    if (_previousValid == valid) return;
    _previousValid = valid;
    widget.onValidChanged?.call(valid);
  }

  void _onTextChanged() {
    final normalized = alienIdSignupNorm(_controller.text);
    if (normalized != _controller.text) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    widget.onChanged?.call(normalized);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _checkAvailability(normalized.trim());
    });
  }

  Future<void> _checkAvailability(String alienId) async {
    if (alienId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _available = null;
        _checkError = false;
        _checkErrorMessage = null;
      });
      _notifyValid(false);
      return;
    }

    if (alienId.length < _minLen) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _available = null;
        _checkError = true;
        _checkErrorMessage = 'Must be at least $_minLen characters';
      });
      _notifyValid(false);
      return;
    }

    setState(() {
      _loading = true;
      _available = null;
      _checkError = false;
      _checkErrorMessage = null;
    });
    _notifyValid(false);

    try {
      final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/v1/auth/alien_id/check').replace(queryParameters: {
        'alien_id': alienId,
        if (widget.referralCode.isNotEmpty) 'referral_code': widget.referralCode,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted || alienIdSignupNorm(_controller.text).trim() != alienId) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ok = data['available'] == true;
        setState(() {
          _loading = false;
          _available = ok;
          _checkError = !ok;
          _checkErrorMessage = ok ? null : (data['message'] as String? ?? 'Alien ID is not available');
        });
        _notifyValid(ok);
      } else {
        setState(() {
          _loading = false;
          _available = null;
          _checkError = true;
          _checkErrorMessage = 'Could not verify Alien ID availability';
        });
        _notifyValid(false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _available = null;
        _checkError = true;
        _checkErrorMessage = 'Network error checking Alien ID';
      });
      _notifyValid(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _available == true;
    final hasError = _checkError && (_checkErrorMessage?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
          ],
          decoration: UiInputDecoration.of(
            context,
            labelText: 'Alien ID',
            hintText: 'your_handle',
            prefixText: '@',
            suffixIcon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399)),
                    ),
                  )
                : available
                    ? const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18)
                    : hasError
                        ? const Icon(Icons.cancel, color: Color(0xFFF87171), size: 18)
                        : null,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _checkErrorMessage!,
              style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFF87171)),
            ),
          )
        else if (available)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '@${_controller.text.trim()} is available',
              style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF34D399)),
            ),
          ),
      ],
    );
  }
}
