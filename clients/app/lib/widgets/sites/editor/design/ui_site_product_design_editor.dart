import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_text_style.dart';
import 'ui_site_block_card_style_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'ui_site_design_nav.dart';
import 'ui_site_featured_strip_design_detail.dart';

// =============================================================================
// Products
// =============================================================================

const siteProductDesignIds = ['card', 'title', 'subtitle', 'price'];

String siteProductDesignLabel(String id) => switch (id) {
      'card' => 'Card',
      'title' => 'Title',
      'subtitle' => 'Subtitle',
      'price' => 'Price',
      _ => id,
    };

String siteProductDesignSubtitle(SiteDesignStore draft, String id) {
  final d = draft.productDesign;
  return switch (id) {
    'card' => siteBlockDesignSubtitle(draft.blockDesignGet('site_product'), draft.cardStyle),
    'title' => '${d.titleFontSize.round()}px · ${siteFontWeightLabel(d.titleFontWeight)}',
    'subtitle' => '${d.subtitleFontSize.round()}px · ${siteFontWeightLabel(d.subtitleFontWeight)}',
    'price' => '${d.priceFontSize.round()}px · ${siteFontWeightLabel(d.priceFontWeight)}',
    _ => '',
  };
}

IconData siteProductDesignIcon(String id) => switch (id) {
      'card' => Icons.style_outlined,
      'title' => Icons.title,
      'subtitle' => Icons.short_text,
      'price' => Icons.sell_outlined,
      _ => Icons.tune,
    };

/// Products appearance — master lists Card + Title / Subtitle / Price.
class UiSiteProductDesignPane extends StatefulWidget {
  const UiSiteProductDesignPane({
    super.key,
    required this.draft,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
    this.designSelected = true,
    this.onToggleDesign,
  });

  final SiteDesignStore draft;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final bool designSelected;
  final VoidCallback? onToggleDesign;

  @override
  State<UiSiteProductDesignPane> createState() => _UiSiteProductDesignPaneState();
}

class _UiSiteProductDesignPaneState extends State<UiSiteProductDesignPane> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _pickDefault();
  }

  @override
  void didUpdateWidget(covariant UiSiteProductDesignPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.masterDetail != oldWidget.masterDetail) _pickDefault();
  }

  void _pickDefault() {
    if (widget.masterDetail) {
      if (_selectedId == null || !siteProductDesignIds.contains(_selectedId)) {
        _selectedId = siteProductDesignIds.first;
      }
      return;
    }
    if (widget.detailId != null && !siteProductDesignIds.contains(widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  Widget _master({required String? selectedId}) => ListenableBuilder(
        listenable: widget.draft,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onToggleDesign != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: siteCatalogPaletteButton(selected: widget.designSelected, onPressed: widget.onToggleDesign!),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  const UiSiteDesignSectionHeader(title: 'Appearance'),
                  UiSiteDesignChoiceRow(
                    label: siteProductDesignLabel('card'),
                    value: siteProductDesignSubtitle(widget.draft, 'card'),
                    icon: siteProductDesignIcon('card'),
                    selected: selectedId == 'card',
                    onTap: () => _select('card'),
                  ),
                  const UiSiteDesignSectionHeader(title: 'Typography'),
                  for (final id in ['title', 'subtitle', 'price']) ...[
                    UiSiteDesignChoiceRow(
                      label: siteProductDesignLabel(id),
                      value: siteProductDesignSubtitle(widget.draft, id),
                      icon: siteProductDesignIcon(id),
                      selected: selectedId == id,
                      onTap: () => _select(id),
                    ),
                    if (id != 'price') const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _detail(String id) => ListenableBuilder(
        listenable: widget.draft,
        builder: (context, _) {
          if (!widget.masterDetail) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => widget.onDetailIdChanged?.call(null),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          siteProductDesignLabel(id),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _detailBody(id)),
              ],
            );
          }
          return _detailBody(id);
        },
      );

  Widget _detailBody(String id) {
    final draft = widget.draft;
    final d = draft.productDesign;
    return switch (id) {
      'card' => ListView(
          padding: const EdgeInsets.all(16),
          children: [UiSiteBlockCardStyleEditor(draft: draft, block: 'site_product')],
        ),
      'title' => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InTextStyle(
              fontFamily: d.titleFontFamily,
              fontSize: d.titleFontSize,
              fontWeight: d.titleFontWeight,
              italic: d.titleItalic,
              underline: d.titleUnderline,
              color: d.titleColor,
              sizeMin: 11,
              sizeMax: 22,
              onFontFamily: (v) => draft.productDesignUpdate(titleFontFamily: v),
              onFontSize: (v) => draft.productDesignUpdate(titleFontSize: v),
              onFontWeight: (v) => draft.productDesignUpdate(titleFontWeight: v),
              onItalic: (v) => draft.productDesignUpdate(titleItalic: v),
              onUnderline: (v) => draft.productDesignUpdate(titleUnderline: v),
              onColor: (v) => draft.productDesignUpdate(titleColor: v),
            ),
          ],
        ),
      'subtitle' => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InTextStyle(
              fontFamily: d.subtitleFontFamily,
              fontSize: d.subtitleFontSize,
              fontWeight: d.subtitleFontWeight,
              italic: d.subtitleItalic,
              underline: d.subtitleUnderline,
              color: d.subtitleColor,
              sizeMin: 10,
              sizeMax: 18,
              onFontFamily: (v) => draft.productDesignUpdate(subtitleFontFamily: v),
              onFontSize: (v) => draft.productDesignUpdate(subtitleFontSize: v),
              onFontWeight: (v) => draft.productDesignUpdate(subtitleFontWeight: v),
              onItalic: (v) => draft.productDesignUpdate(subtitleItalic: v),
              onUnderline: (v) => draft.productDesignUpdate(subtitleUnderline: v),
              onColor: (v) => draft.productDesignUpdate(subtitleColor: v),
            ),
          ],
        ),
      'price' => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InTextStyle(
              fontFamily: d.priceFontFamily,
              fontSize: d.priceFontSize,
              fontWeight: d.priceFontWeight,
              italic: d.priceItalic,
              underline: d.priceUnderline,
              color: d.priceColor,
              sizeMin: 11,
              sizeMax: 22,
              onFontFamily: (v) => draft.productDesignUpdate(priceFontFamily: v),
              onFontSize: (v) => draft.productDesignUpdate(priceFontSize: v),
              onFontWeight: (v) => draft.productDesignUpdate(priceFontWeight: v),
              onItalic: (v) => draft.productDesignUpdate(priceItalic: v),
              onUnderline: (v) => draft.productDesignUpdate(priceUnderline: v),
              onColor: (v) => draft.productDesignUpdate(priceColor: v),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final id = _activeId ?? (widget.masterDetail ? siteProductDesignIds.first : null);
    return UiSiteDesignMasterDetail(
      masterDetail: widget.masterDetail,
      detailId: id,
      master: _master(selectedId: id),
      detail: id == null ? const SizedBox.shrink() : _detail(id),
    );
  }
}

// =============================================================================
// Links
// =============================================================================

const siteLinkDesignIds = ['container'];

/// Links appearance — master lists Container (site-level).
class UiSiteLinkDesignPane extends StatefulWidget {
  const UiSiteLinkDesignPane({
    super.key,
    required this.draft,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
    this.designSelected = true,
    this.onToggleDesign,
  });

  final SiteDesignStore draft;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final bool designSelected;
  final VoidCallback? onToggleDesign;

  @override
  State<UiSiteLinkDesignPane> createState() => _UiSiteLinkDesignPaneState();
}

class _UiSiteLinkDesignPaneState extends State<UiSiteLinkDesignPane> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _pickDefault();
  }

  void _pickDefault() {
    if (widget.masterDetail) {
      _selectedId ??= siteLinkDesignIds.first;
      return;
    }
    if (widget.detailId != null && !siteLinkDesignIds.contains(widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  String _containerSubtitle() {
    final existing = widget.draft.blockDesignGet('link');
    if (existing?.isBare ?? false) return 'Off';
    if (existing == null || existing.inheritsGlobal) return 'Theme cards';
    return siteCardStyleSubtitle(SiteCardStyleDraft(id: existing.cardStyleId, params: existing.params));
  }

  bool get _linkContainerOn => !(widget.draft.blockDesignGet('link')?.isBare ?? false);

  void _setLinkContainerOn(bool on) {
    if (on) {
      widget.draft.blockDesignPut(SiteBlockDesignDraft(block: 'link'));
    } else {
      widget.draft.blockDesignPut(const SiteBlockDesignDraft(block: 'link', cardStyleId: 'none'));
    }
  }

  Widget _master({required String? selectedId}) => ListenableBuilder(
        listenable: widget.draft,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onToggleDesign != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: siteCatalogPaletteButton(selected: widget.designSelected, onPressed: widget.onToggleDesign!),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  const UiSiteDesignSectionHeader(title: 'Appearance'),
                  UiSiteDesignChoiceRow(
                    label: 'Container',
                    value: _containerSubtitle(),
                    icon: Icons.crop_square_outlined,
                    selected: selectedId == 'container',
                    toggleValue: _linkContainerOn,
                    onToggleChanged: _setLinkContainerOn,
                    onTap: () => _select('container'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _detail(String id) {
    final body = _linkContainerOn
        ? ListView(
            padding: const EdgeInsets.all(16),
            children: [UiSiteBlockCardStyleEditor(draft: widget.draft, block: 'link', allowBare: true)],
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Container is off. Links show without a background.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          );
    if (widget.masterDetail) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => widget.onDetailIdChanged?.call(null),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text('Container', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _activeId ?? (widget.masterDetail ? siteLinkDesignIds.first : null);
    return UiSiteDesignMasterDetail(
      masterDetail: widget.masterDetail,
      detailId: id,
      master: _master(selectedId: id),
      detail: id == null ? const SizedBox.shrink() : _detail(id),
    );
  }
}

// =============================================================================
// Contacts
// =============================================================================

const siteContactsDesignIds = [
  'partners_header',
  'partners_item',
  'partners_card',
  'clients_header',
  'clients_item',
  'clients_card',
];

String siteContactsDesignLabel(String id) => switch (id) {
      'partners_header' || 'clients_header' => 'Header',
      'partners_item' || 'clients_item' => 'Item',
      'partners_card' || 'clients_card' => 'Card',
      _ => id,
    };

String siteContactsDesignBlock(String id) => id.startsWith('partners') ? 'partners_display' : 'clients_display';

String siteContactsDesignKind(String id) => id.startsWith('partners') ? 'partners' : 'clients';

String siteContactsDesignPart(String id) {
  if (id.endsWith('_header')) return 'header';
  if (id.endsWith('_item')) return 'item';
  return 'card';
}

/// Contacts appearance — Partners / Clients groups with Header · Item · Card.
class UiSiteContactsDesignPane extends StatefulWidget {
  const UiSiteContactsDesignPane({
    super.key,
    required this.draft,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
    this.designSelected = true,
    this.onToggleDesign,
  });

  final SiteDesignStore draft;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final bool designSelected;
  final VoidCallback? onToggleDesign;

  @override
  State<UiSiteContactsDesignPane> createState() => _UiSiteContactsDesignPaneState();
}

class _UiSiteContactsDesignPaneState extends State<UiSiteContactsDesignPane> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _pickDefault();
  }

  void _pickDefault() {
    if (widget.masterDetail) {
      if (_selectedId == null || !siteContactsDesignIds.contains(_selectedId)) {
        _selectedId = siteContactsDesignIds.first;
      }
      return;
    }
    if (widget.detailId != null && !siteContactsDesignIds.contains(widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  String _rowSubtitle(String id) {
    final strip = widget.draft.featuredStripGet(siteContactsDesignKind(id));
    return switch (siteContactsDesignPart(id)) {
      'header' => siteFeaturedStripSubtitle(strip),
      'item' => siteFeaturedStripItemModeLabel(strip.itemMode),
      _ => siteBlockDesignSubtitle(widget.draft.blockDesignGet(siteContactsDesignBlock(id)), widget.draft.cardStyle),
    };
  }

  Widget _master({required String? selectedId}) => ListenableBuilder(
        listenable: widget.draft,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onToggleDesign != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    siteCatalogPaletteButton(selected: widget.designSelected, onPressed: widget.onToggleDesign!),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  for (final (group, ids) in [
                    ('Partners', ['partners_header', 'partners_item', 'partners_card']),
                    ('Clients', ['clients_header', 'clients_item', 'clients_card']),
                  ]) ...[
                    UiSiteDesignSectionHeader(title: group),
                    for (final id in ids) ...[
                      UiSiteDesignChoiceRow(
                        label: siteContactsDesignLabel(id),
                        value: _rowSubtitle(id),
                        icon: switch (siteContactsDesignPart(id)) {
                          'header' => Icons.title,
                          'item' => Icons.view_carousel_outlined,
                          _ => Icons.style_outlined,
                        },
                        selected: selectedId == id,
                        onTap: () => _select(id),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _detail(String id) {
    final block = siteContactsDesignBlock(id);
    final part = siteContactsDesignPart(id);
    final body = switch (part) {
      'header' => UiSiteFeaturedStripHeaderDetail(draft: widget.draft, itemId: block),
      'item' => UiSiteFeaturedStripItemDetail(draft: widget.draft, itemId: block, includeCard: false),
      _ => ListView(
          padding: const EdgeInsets.all(16),
          children: [UiSiteBlockCardStyleEditor(draft: widget.draft, block: block)],
        ),
    };
    if (widget.masterDetail) return body;
    final group = id.startsWith('partners') ? 'Partners' : 'Clients';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => widget.onDetailIdChanged?.call(null),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  '$group · ${siteContactsDesignLabel(id)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _activeId ?? (widget.masterDetail ? siteContactsDesignIds.first : null);
    return UiSiteDesignMasterDetail(
      masterDetail: widget.masterDetail,
      detailId: id,
      master: _master(selectedId: id),
      detail: id == null ? const SizedBox.shrink() : _detail(id),
    );
  }
}

/// Scrollable all-in-one product editor for Design section (no nested master).
class UiSiteProductDesignEditor extends StatelessWidget {
  const UiSiteProductDesignEditor({super.key, required this.draft});

  final SiteDesignStore draft;

  @override
  Widget build(BuildContext context) => UiSiteProductDesignPane(draft: draft, masterDetail: true);
}

class UiSiteLinkDesignEditor extends StatelessWidget {
  const UiSiteLinkDesignEditor({super.key, required this.draft});

  final SiteDesignStore draft;

  @override
  Widget build(BuildContext context) => UiSiteLinkDesignPane(draft: draft, masterDetail: true);
}

class UiSiteContactsDesignEditor extends StatelessWidget {
  const UiSiteContactsDesignEditor({super.key, required this.draft});

  final SiteDesignStore draft;

  @override
  Widget build(BuildContext context) => UiSiteContactsDesignPane(draft: draft, masterDetail: true);
}
