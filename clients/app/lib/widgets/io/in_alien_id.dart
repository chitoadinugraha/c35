import 'dart:async';

import 'package:alienai_c35/c/profile/alien_id.dart';
import 'package:alienai_c35/c/profile/profile_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InAlienId extends StatefulWidget {
  const InAlienId({super.key, this.controller, required this.profile, required this.uid, this.initial = '', this.onChanged, this.onValidChanged});

  final TextEditingController? controller;
  final ProfileApi profile;
  final int uid;
  final String initial;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidChanged;

  @override
  State<InAlienId> createState() => _InAlienIdState();
}

class _InAlienIdState extends State<InAlienId> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  Timer? _debounce;
  var _loading = false;
  bool? _available;
  var _checkError = false;
  String? _checkErrorMessage;
  bool? _previousValid;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController(text: alienIdNormalize(widget.initial));
    _controller.addListener(_onTextChanged);
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
    final normalized = alienIdNormalize(_controller.text);
    if (normalized != _controller.text) {
      _controller.value = TextEditingValue(text: normalized, selection: TextSelection.collapsed(offset: normalized.length));
    }
    widget.onChanged?.call(normalized);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _checkAvailability(normalized.trim()));
  }

  Future<void> _checkAvailability(String alienId) async {
    final formatErr = alienIdFormatError(alienId);
    if (formatErr != null) {
      if (!mounted) return;
      setState(() {
        _available = null;
        _loading = false;
        _checkError = alienId.isNotEmpty;
        _checkErrorMessage = formatErr;
      });
      _notifyValid(false);
      return;
    }
    if (alienIdNormalize(widget.initial) == alienId) {
      if (!mounted) return;
      setState(() {
        _available = true;
        _loading = false;
        _checkError = false;
        _checkErrorMessage = null;
      });
      _notifyValid(true);
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
      final res = await widget.profile.alienIdCheck(uid: widget.uid, alienId: alienId);
      if (!mounted || alienIdNormalize(_controller.text).trim() != alienId) return;
      setState(() {
        _available = res.available;
        _loading = false;
        _checkError = res.message.isNotEmpty && !res.available;
        _checkErrorMessage = res.message.isNotEmpty ? res.message : null;
      });
      _notifyValid(res.available);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _available = null;
        _loading = false;
        _checkError = true;
        _checkErrorMessage = uiFriendlyError(e, fallback: 'Could not check Alien ID.');
      });
      _notifyValid(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAvailable = !_loading && _available == true;
    final showTaken = !_loading && _available == false && !_checkError;
    String? helperText;
    TextStyle? helperStyle;
    if (!_checkError && !showTaken) {
      if (_loading) {
        helperText = 'Checking…';
        helperStyle = const TextStyle(color: Color(0xFF71717A), fontSize: 12);
      } else if (showAvailable) {
        helperText = 'Alien ID available';
        helperStyle = const TextStyle(color: Color(0xFF34D399), fontSize: 12);
      } else if (_controller.text.trim().isNotEmpty) {
        helperText = 'a-z, 0-9, _ , - · $alienIdMinLen–$alienIdMaxLen';
        helperStyle = const TextStyle(color: Color(0xFF71717A), fontSize: 12);
      }
    }
    return TextField(
      controller: _controller,
      maxLength: alienIdMaxLen,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        labelText: 'Alien ID',
        labelStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
        suffixText: '@alienai.id',
        suffixStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 13),
        suffixIcon: _loading
            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399))))
            : null,
        errorText: _checkError ? (_checkErrorMessage ?? 'Could not check Alien ID') : (showTaken ? 'Alien ID already taken' : null),
        helperText: helperText,
        helperStyle: helperStyle,
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF27272A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF27272A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34D399))),
      ),
      style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 14),
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
        TextInputFormatter.withFunction((old, neu) {
          final lower = neu.text.toLowerCase();
          return lower == neu.text ? neu : neu.copyWith(text: lower);
        }),
      ],
    );
  }
}
