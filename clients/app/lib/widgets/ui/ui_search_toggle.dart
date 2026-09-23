import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSearchToggle extends StatefulWidget {
  const UiSearchToggle({
    super.key,
    required this.onSearch,
    this.hint = 'Search',
    this.initial = '',
    this.trailing,
    this.compact = false,
  });

  final ValueChanged<String> onSearch;
  final String hint;
  final String initial;
  final Widget? trailing;
  final bool compact;

  @override
  State<UiSearchToggle> createState() => _UiSearchToggleState();
}

class _UiSearchToggleState extends State<UiSearchToggle> {
  var _open = false;
  late final _ctrl = TextEditingController(text: widget.initial);
  late final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => widget.onSearch(_ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeSearch() {
    _ctrl.clear();
    _focus.unfocus();
    setState(() => _open = false);
  }

  Widget _field() => TextField(
        controller: _ctrl,
        focusNode: _focus,
        style: TextStyle(fontSize: widget.compact ? 12 : 13, color: const Color(0xFFF4F4F5)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: _muted, fontSize: widget.compact ? 12 : 13),
          prefixIcon: Icon(Icons.search, size: widget.compact ? 14 : 16, color: _muted),
          prefixIconConstraints: BoxConstraints(minWidth: widget.compact ? 32 : 36, minHeight: 32),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF18181B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_open) {
      return Row(
        children: [
          Expanded(child: _field()),
          uiIconButton(
            tooltip: _ctrl.text.isNotEmpty ? 'Clear' : 'Close search',
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFA1A1AA)),
            onPressed: _ctrl.text.isNotEmpty
                ? () {
                    _ctrl.clear();
                    _focus.requestFocus();
                  }
                : _closeSearch,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        uiIconButton(tooltip: 'Search', onPressed: _openSearch, icon: const Icon(Icons.search, size: 18, color: Color(0xFFA1A1AA))),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }
}
