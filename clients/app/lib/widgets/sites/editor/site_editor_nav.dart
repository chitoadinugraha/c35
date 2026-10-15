import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/sites/editor/design/ui_site_design_section.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_ai_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_products_editor.dart';
import 'package:flutter/material.dart';

/// Breadcrumb / chrome segment (UI built in shell).
class SiteEditorNavSegment {
  const SiteEditorNavSegment({
    required this.kind,
    required this.label,
    this.sectionId,
    this.detailId,
    required this.depth,
  });

  final SiteEditorNavSegmentKind kind;
  final String label;
  final String? sectionId;
  final String? detailId;

  /// 0 = site handle, 1 = section, 2+ = in-section drill.
  final int depth;
}

enum SiteEditorNavSegmentKind { handle, section, catalogDetail, productsPane, aiPane }

sealed class SiteEditorNavFrame {
  const SiteEditorNavFrame();
}

class SiteEditorNavCatalogDetailFrame extends SiteEditorNavFrame {
  SiteEditorNavCatalogDetailFrame({
    required this.sectionId,
    required this.detailId,
    this.label,
  });

  final String sectionId;
  final String detailId;
  String? label;
}

class SiteEditorNavProductsPaneFrame extends SiteEditorNavFrame {
  const SiteEditorNavProductsPaneFrame(this.pane);

  final SiteProductsPane pane;
}

class SiteEditorNavAiPaneFrame extends SiteEditorNavFrame {
  const SiteEditorNavAiPaneFrame(this.pane);

  final SiteAiPane pane;
}

/// Single navigation model for site editor drill-down and sub-panes.
class SiteEditorNav {
  SiteEditorNav();

  /// Null on narrow = section menu. Wide layout uses rail selection.
  String? section;

  final List<SiteEditorNavFrame> _stack = [];

  List<SiteEditorNavFrame> get frames => List.unmodifiable(_stack);

  String? get catalogDetailId {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final f = _stack[i];
      if (f is SiteEditorNavCatalogDetailFrame) return f.detailId;
    }
    return null;
  }

  SiteProductsPane get productsPane {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final f = _stack[i];
      if (f is SiteEditorNavProductsPaneFrame) return f.pane;
    }
    return SiteProductsPane.list;
  }

  SiteAiPane get aiPane {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final f = _stack[i];
      if (f is SiteEditorNavAiPaneFrame) return f.pane;
    }
    return SiteAiPane.list;
  }

  void openSection(String id) {
    section = id;
    _stack.clear();
  }

  void openNarrowMenu() {
    section = null;
    _stack.clear();
  }

  void pushDetail({required String sectionId, required String detailId, String? label}) {
    _removeWhereType<SiteEditorNavCatalogDetailFrame>();
    if (detailId.isEmpty) return;
    _stack.add(SiteEditorNavCatalogDetailFrame(sectionId: sectionId, detailId: detailId, label: label));
  }

  void setDetailId(String? id, {required String sectionId, String? label}) {
    _removeWhereType<SiteEditorNavCatalogDetailFrame>();
    if (id == null || id.isEmpty) return;
    _stack.add(SiteEditorNavCatalogDetailFrame(sectionId: sectionId, detailId: id, label: label));
  }

  void updateCatalogDetailLabel(String detailId, String label) {
    for (final f in _stack) {
      if (f is SiteEditorNavCatalogDetailFrame && f.detailId == detailId) {
        f.label = label;
        return;
      }
    }
  }

  void pushProductsPane(SiteProductsPane pane) {
    _removeWhereType<SiteEditorNavProductsPaneFrame>();
    if (pane == SiteProductsPane.list) return;
    _stack.add(SiteEditorNavProductsPaneFrame(pane));
  }

  void pushAiPane(SiteAiPane pane) {
    _removeWhereType<SiteEditorNavAiPaneFrame>();
    if (pane == SiteAiPane.list) return;
    _stack.add(SiteEditorNavAiPaneFrame(pane));
  }

  void pop() {
    if (productsPane != SiteProductsPane.list) {
      _removeWhereType<SiteEditorNavProductsPaneFrame>();
      return;
    }
    if (aiPane != SiteAiPane.list) {
      _removeWhereType<SiteEditorNavAiPaneFrame>();
      return;
    }
    _removeWhereType<SiteEditorNavCatalogDetailFrame>();
  }

  /// Navigate breadcrumb tap: 0 = handle, 1 = section list, deeper = pop overlays.
  void popToBreadcrumbDepth(int depth) {
    if (depth <= 0) return;
    if (depth == 1) {
      _stack.clear();
      return;
    }
    final targetFrames = depth - 1;
    while (_stack.length > targetFrames) {
      pop();
    }
  }

  bool canPop({required bool wide}) {
    if (productsPane != SiteProductsPane.list) return true;
    if (aiPane != SiteAiPane.list) return true;
    if (wide && narrowCatalogDrill(section ?? '')) return true;
    if (!wide && narrowCatalogDrill(section ?? '')) return true;
    if (!wide && section != null) return true;
    return false;
  }

  bool narrowCatalogDrill(String section) {
    if (section == 'products' && (productsPane != SiteProductsPane.list || catalogDetailId != null)) {
      return true;
    }
    if (section == 'ai' && (aiPane != SiteAiPane.list || catalogDetailId != null)) {
      return true;
    }
    if (_catalogDetailSections.contains(section) && catalogDetailId != null) {
      return true;
    }
    return false;
  }

  bool catalogMasterDetail(
    BuildContext context, {
    required bool wide,
    required String section,
    required double previewPaneW,
  }) {
    if (!wide) return false;
    if (section == 'products' && productsPane != SiteProductsPane.list) return false;
    if (section == 'ai' && aiPane != SiteAiPane.list) return false;
    if (!_masterDetailSections.contains(section)) return false;
    final w = MediaQuery.sizeOf(context).width;
    return w - siteEditorMenuRailW - previewPaneW >= siteEditorMasterDetailBreakpoint;
  }

  List<SiteEditorNavSegment> pathSegments({
    required SiteEditorCaps caps,
    required String handleLabel,
    required bool wide,
  }) {
    final out = <SiteEditorNavSegment>[];
    if (handleLabel.isNotEmpty) {
      out.add(SiteEditorNavSegment(kind: SiteEditorNavSegmentKind.handle, label: handleLabel, depth: 0));
    }
    if (wide && (section == null || section!.isEmpty)) {
      return out;
    }
    if (!wide && (section == null || section!.isEmpty)) {
      return out;
    }
    final sec = section!;
    out.add(
      SiteEditorNavSegment(
        kind: SiteEditorNavSegmentKind.section,
        label: siteEditorMenuLabel(sec, caps: caps) ?? sec,
        sectionId: sec,
        depth: 1,
      ),
    );
    for (final frame in _stack) {
      switch (frame) {
        case SiteEditorNavCatalogDetailFrame():
          final label = frame.label ??
              (frame.sectionId == 'design' ? siteDesignNavLabelTr(frame.detailId) : frame.detailId);
          out.add(
            SiteEditorNavSegment(
              kind: SiteEditorNavSegmentKind.catalogDetail,
              label: label,
              sectionId: frame.sectionId,
              detailId: frame.detailId,
              depth: out.length,
            ),
          );
        case SiteEditorNavProductsPaneFrame():
          out.add(
            SiteEditorNavSegment(
              kind: SiteEditorNavSegmentKind.productsPane,
              label: siteProductsPaneLabel(frame.pane),
              sectionId: 'products',
              depth: out.length,
            ),
          );
        case SiteEditorNavAiPaneFrame():
          out.add(
            SiteEditorNavSegment(
              kind: SiteEditorNavSegmentKind.aiPane,
              label: siteAiPaneLabel(frame.pane),
              sectionId: 'ai',
              depth: out.length,
            ),
          );
      }
    }
    return out;
  }

  void _removeWhereType<T extends SiteEditorNavFrame>() {
    _stack.removeWhere((f) => f is T);
  }

  static const masterDetailSectionIds = {
    'design',
    'products',
    'links',
    'contacts',
    'objects',
    'attendance',
    'accounts',
    'queue',
    'team',
    'effects',
    'ai',
    'posts',
  };

  static const _masterDetailSections = masterDetailSectionIds;

  static const _catalogDetailSections = {
    'design',
    'products',
    'links',
    'contacts',
    'objects',
    'attendance',
    'accounts',
    'queue',
    'team',
    'effects',
    'ai',
    'posts',
  };
}

/// Lets catalog editors push human-readable breadcrumb labels.
class SiteEditorNavScope extends InheritedWidget {
  const SiteEditorNavScope({
    super.key,
    required this.nav,
    required this.onNavChanged,
    required super.child,
  });

  final SiteEditorNav nav;
  final VoidCallback onNavChanged;

  static SiteEditorNavScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteEditorNavScope>();

  static void reportDetailLabel(BuildContext context, String detailId, String label) {
    final scope = maybeOf(context);
    if (scope == null || label.trim().isEmpty) return;
    scope.nav.updateCatalogDetailLabel(detailId, label.trim());
    scope.onNavChanged();
  }

  @override
  bool updateShouldNotify(SiteEditorNavScope oldWidget) => oldWidget.nav != nav;
}
