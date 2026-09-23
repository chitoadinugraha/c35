import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _masterBg = Color(0xFF0C0C10);
const _muted = Color(0xFF71717A);

class UiMasterDetail extends StatelessWidget {
  const UiMasterDetail({
    super.key,
    this.nav,
    required this.master,
    required this.detailBuilder,
    this.selectedId,
    this.onSelectedIdChanged,
    this.breakpoint = 720,
    this.navWidth = 200,
    this.masterWidth = 320,
    this.onDrillBack,
    this.emptyDetail,
    this.collapseWhenEmpty = false,
    this.listEmpty = false,
    this.masterBar,
  });

  final Widget? nav;
  final Widget master;
  final Widget Function(String? id) detailBuilder;
  final String? selectedId;
  final ValueChanged<String?>? onSelectedIdChanged;
  final double breakpoint;
  final double navWidth;
  final double masterWidth;
  final VoidCallback? onDrillBack;
  final Widget? emptyDetail;
  final bool collapseWhenEmpty;
  final bool listEmpty;
  final Widget? masterBar;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= breakpoint;
    final hasSelection = selectedId != null;

    if (wide && collapseWhenEmpty && listEmpty) {
      final pane = _masterPane(nav ?? master);
      return ColoredBox(color: uiPageBg, child: _pane(pane, bg: _masterBg));
    }

    if (wide) {
      return ColoredBox(
        color: uiPageBg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nav != null) ...[
              SizedBox(width: navWidth, child: _pane(nav!, bg: _masterBg)),
              const VerticalDivider(width: 1, color: _border),
            ],
            SizedBox(width: masterWidth, child: _pane(_masterPane(master), bg: _masterBg)),
            const VerticalDivider(width: 1, color: _border),
            Expanded(child: _detailPane(hasSelection)),
          ],
        ),
      );
    }

    if (!hasSelection) return _masterPane(nav ?? master);

    return ColoredBox(color: uiPageBg, child: detailBuilder(selectedId));
  }

  Widget _masterPane(Widget list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (masterBar != null) masterBar!,
          Expanded(child: list),
        ],
      );

  Widget _pane(Widget child, {Color bg = uiPageBg}) => ColoredBox(color: bg, child: child);

  Widget _detailPane(bool hasSelection) {
    if (!hasSelection) {
      return emptyDetail ??
          const Center(
            child: Text('Select an item', style: TextStyle(color: _muted, fontSize: 13)),
          );
    }
    return detailBuilder(selectedId);
  }
}
