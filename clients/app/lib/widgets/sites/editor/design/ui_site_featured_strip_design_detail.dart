import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_font.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'ui_site_block_card_style_editor.dart';

Widget _segmentedAlign({
  required BuildContext context,
  required String label,
  required String value,
  required ValueChanged<String> onSelect,
}) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'left', label: Text('site.design.alignLeft'.tr()), icon: const Icon(Icons.format_align_left, size: 18)),
          ButtonSegment(value: 'center', label: Text('site.design.alignCenter'.tr()), icon: const Icon(Icons.format_align_center, size: 18)),
          ButtonSegment(value: 'right', label: Text('site.design.alignRight'.tr()), icon: const Icon(Icons.format_align_right, size: 18)),
        ],
        selected: {value},
        showSelectedIcon: false,
        style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onSelectionChanged: (s) => onSelect(s.first),
      ),
      const SizedBox(height: 4),
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
    ],
  );
}

class _FeaturedStripModePicker extends StatelessWidget {
  const _FeaturedStripModePicker({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = siteFeaturedStripItemModeNormalize(value);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (id, label) in siteFeaturedStripItemModeOptions)
          SizedBox(
            width: 104,
            child: Material(
              color: mode == id ? cs.primaryContainer.withValues(alpha: 0.45) : cs.surfaceContainerHighest.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: mode == id ? cs.primary.withValues(alpha: 0.55) : cs.outlineVariant.withValues(alpha: 0.4),
                  width: mode == id ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FeaturedStripModeSketch(mode: id, color: cs.onSurface),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: mode == id ? FontWeight.w700 : FontWeight.w500,
                              color: mode == id ? cs.primary : cs.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedStripModeSketch extends StatelessWidget {
  const _FeaturedStripModeSketch({required this.mode, required this.color});

  final String mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = color.withValues(alpha: 0.35);
    final avatar = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, color: muted),
    );
    final nameBar = Container(
      height: 5,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: muted, borderRadius: BorderRadius.circular(2)),
    );
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        if (mode != siteFeaturedStripItemModeIcon) nameBar,
      ],
    );
    if (mode == siteFeaturedStripItemModeCard) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          color: color.withValues(alpha: 0.06),
        ),
        child: inner,
      );
    }
    return SizedBox(height: 52, child: Center(child: inner));
  }
}

/// Featured strip header fields only.
class UiSiteFeaturedStripHeaderDetail extends StatefulWidget {
  const UiSiteFeaturedStripHeaderDetail({super.key, required this.draft, required this.itemId});

  final SiteDesignStore draft;
  final String itemId;

  @override
  State<UiSiteFeaturedStripHeaderDetail> createState() => _UiSiteFeaturedStripHeaderDetailState();
}

class _UiSiteFeaturedStripHeaderDetailState extends State<UiSiteFeaturedStripHeaderDetail> {
  late final TextEditingController _headerCtrl;

  String get _kind => siteFeaturedDisplayKind(widget.itemId);
  SiteFeaturedStripDraft get _config => widget.draft.featuredStripGet(_kind);

  @override
  void initState() {
    super.initState();
    _headerCtrl = TextEditingController(text: _config.header);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteFeaturedStripHeaderDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId || oldWidget.draft.featuredStripGet(_kind).header != _config.header) {
      final next = _config.header;
      if (_headerCtrl.text != next) {
        _headerCtrl.value = _headerCtrl.value.copyWith(text: next, selection: TextSelection.collapsed(offset: next.length));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final config = _config;
    final defaultHeader = siteFeaturedDisplayDefaultHeader(widget.itemId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _headerCtrl,
          decoration: UiInputDecoration.of(context, labelText: 'site.stripDesign.header'.tr(), hintText: defaultHeader),
          onChanged: (v) => draft.featuredStripUpdate(_kind, header: v),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('site.stripDesign.showLabel'.tr()),
          value: config.showLabel,
          onChanged: (v) => draft.featuredStripUpdate(_kind, showLabel: v ?? true),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        _segmentedAlign(
          context: context,
          label: 'site.stripDesign.headerAlign'.tr(),
          value: config.headerAlign,
          onSelect: (v) => draft.featuredStripUpdate(_kind, headerAlign: v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('site.design.fontSize'.tr(), style: Theme.of(context).textTheme.labelLarge)),
            Text('${config.headerFontSize.round()}px', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Slider(
          value: config.headerFontSize.clamp(10, 28),
          min: 10,
          max: 28,
          divisions: 18,
          onChanged: (v) => draft.featuredStripUpdate(_kind, headerFontSize: v),
        ),
        const SizedBox(height: 8),
        InFont(
          value: config.headerFontFamily,
          onChanged: (v) => draft.featuredStripUpdate(_kind, headerFontFamily: v),
        ),
      ],
    );
  }
}

/// Featured strip item layout fields (optionally with card style).
class UiSiteFeaturedStripItemDetail extends StatelessWidget {
  const UiSiteFeaturedStripItemDetail({
    super.key,
    required this.draft,
    required this.itemId,
    this.includeCard = true,
  });

  final SiteDesignStore draft;
  final String itemId;
  final bool includeCard;

  @override
  Widget build(BuildContext context) {
    final kind = siteFeaturedDisplayKind(itemId);
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final config = draft.featuredStripGet(kind);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('site.stripDesign.display'.tr(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'site.stripDesign.stripItemHint'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _FeaturedStripModePicker(
              value: config.itemMode,
              onSelected: (id) => draft.featuredStripUpdate(kind, itemMode: id),
            ),
            const SizedBox(height: 20),
            _segmentedAlign(
              context: context,
              label: 'site.stripDesign.itemAlign'.tr(),
              value: config.itemAlign,
              onSelect: (v) => draft.featuredStripUpdate(kind, itemAlign: v),
            ),
            const SizedBox(height: 16),
            Text('site.stripDesign.slideFrom'.tr(), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'left', label: Text('site.design.alignLeft'.tr()), icon: const Icon(Icons.west, size: 18)),
                ButtonSegment(value: 'right', label: Text('site.design.alignRight'.tr()), icon: const Icon(Icons.east, size: 18)),
              ],
              selected: {config.slideFrom},
              showSelectedIcon: false,
              style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onSelectionChanged: (s) => draft.featuredStripUpdate(kind, slideFrom: s.first),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'site.stripDesign.autoScrollHint'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            if (includeCard && siteFeaturedStripItemModeUsesCard(config.itemMode)) ...[
              const Divider(height: 32),
              UiSiteBlockCardStyleEditor(draft: draft, block: itemId),
            ],
          ],
        );
      },
    );
  }
}

/// Partners / Clients strip appearance — Header + Item tabs (Design section).
class UiSiteFeaturedStripDesignDetail extends StatefulWidget {
  const UiSiteFeaturedStripDesignDetail({super.key, required this.draft, required this.itemId});

  final SiteDesignStore draft;
  final String itemId;

  @override
  State<UiSiteFeaturedStripDesignDetail> createState() => _UiSiteFeaturedStripDesignDetailState();
}

class _UiSiteFeaturedStripDesignDetailState extends State<UiSiteFeaturedStripDesignDetail> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'site.stripDesign.tabHeader'.tr()),
              Tab(text: 'site.stripDesign.tabItem'.tr()),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                UiSiteFeaturedStripHeaderDetail(draft: widget.draft, itemId: widget.itemId),
                UiSiteFeaturedStripItemDetail(draft: widget.draft, itemId: widget.itemId),
              ],
            ),
          ),
        ],
      );
}
