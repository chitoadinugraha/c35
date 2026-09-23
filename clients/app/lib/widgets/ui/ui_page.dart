import 'package:alienai_c35/widgets/ui/ui_page_bar.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

const uiPageBg = Color(0xFF08080A);

class UiPage extends StatefulWidget {
  const UiPage({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.onBack,
    this.trailing,
    required this.body,
    this.backgroundColor = uiPageBg,
    this.overlay,
    this.floatingActionButton,
    this.onSearch,
    this.searchHint,
    this.searchInitial = '',
    this.hideBar = false,
  });

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget body;
  final Color backgroundColor;
  final Widget? overlay;
  final Widget? floatingActionButton;
  final ValueChanged<String>? onSearch;
  final String? searchHint;
  final String searchInitial;
  final bool hideBar;

  @override
  State<UiPage> createState() => _UiPageState();
}

class _UiPageState extends State<UiPage> {
  static const _muted = Color(0xFF71717A);

  var _searchOpen = false;
  late final _searchCtrl = TextEditingController(text: widget.searchInitial);
  late final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.onSearch?.call(_searchCtrl.text);
    setState(() {});
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _searchOpen = false);
  }

  Widget _searchBar() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
              decoration: InputDecoration(
                hintText: widget.searchHint ?? 'Search',
                hintStyle: const TextStyle(color: _muted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 16, color: _muted),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF18181B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
          uiIconButton(
            tooltip: _searchCtrl.text.isNotEmpty ? 'Clear' : 'Close search',
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFA1A1AA)),
            onPressed: _searchCtrl.text.isNotEmpty
                ? () {
                    _searchCtrl.clear();
                    _searchFocus.requestFocus();
                  }
                : _closeSearch,
          ),
        ],
      );

  Widget? _trailing() {
    if (_searchOpen) return null;
    if (widget.onSearch == null) return widget.trailing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        uiIconButton(tooltip: 'Search', onPressed: _openSearch, icon: const Icon(Icons.search, size: 18, color: Color(0xFFA1A1AA))),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  Widget _bar() {
    final bar = UiPageBar(
      title: widget.title,
      subtitle: widget.subtitle,
      titleWidget: _searchOpen ? null : widget.titleWidget,
      onBack: widget.onBack,
      trailing: _trailing(),
      searchWidget: _searchOpen ? _searchBar() : null,
    );
    return uiDesktopWindow ? bar : SafeArea(bottom: false, child: bar);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: widget.backgroundColor,
        floatingActionButton: widget.floatingActionButton,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.hideBar) _bar(),
                Expanded(child: widget.body),
              ],
            ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      );
}
