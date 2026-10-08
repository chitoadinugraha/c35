import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/site_backdrop.dart';
import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_hub.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_design_resolve.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/design/site_theme.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_backdrop.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_card_style.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_color.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_color_stops.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_font.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_not_found.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'ui_site_block_card_style_editor.dart';
import 'ui_site_featured_strip_design_detail.dart';
import 'ui_site_product_design_editor.dart';

String siteDesignNavLabelTr(String id) => switch (id) {
      'theme' => 'site.design.theme'.tr(),
      'cards' => 'site.design.cards'.tr(),
      'background' => 'site.design.background'.tr(),
      'backdrop' => 'site.design.backdrop'.tr(),
      _ => 'site.design.blocks.$id'.tr(),
    };

String _designBlockLabelTr(String id) => 'site.design.blocks.$id'.tr();

class UiSiteDesignSection extends StatefulWidget {
  const UiSiteDesignSection({
    super.key,
    required this.draft,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteDesignStore draft;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteDesignSection> createState() => _UiSiteDesignSectionState();
}

class _UiSiteDesignSectionState extends State<UiSiteDesignSection> {
  String? _selectedId;
  late final _themeSearchCtrl = TextEditingController();
  var _themeSearch = '';

  @override
  void initState() {
    super.initState();
    _pickDefault();
  }

  @override
  void dispose() {
    _themeSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteDesignSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.masterDetail != oldWidget.masterDetail) _pickDefault();
    if (_selectedId != null && !siteDesignItemIds.contains(_selectedId)) _pickDefault();
  }

  void _pickDefault() {
    if (widget.masterDetail) {
      if (_selectedId == null || !siteDesignItemIds.contains(_selectedId)) {
        _selectedId = siteDesignAppearanceIds.first;
      }
      return;
    }
    if (widget.detailId != null && !siteDesignItemIds.contains(widget.detailId)) {
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

  String _backgroundSubtitle(SiteDesignStore draft) {
    if (siteBackgroundConflictsTheme(draft.background, draft.themeDark)) {
      return 'site.design.bgConflictsTheme'.tr();
    }
    final bg = draft.background;
    return switch (bg.type) {
      'color' => bg.color.isNotEmpty ? 'site.design.bgColor'.tr(namedArgs: {'color': bg.color.toUpperCase()}) : 'site.design.themeDefault'.tr(),
      'image' => bg.url.isNotEmpty ? 'site.design.image'.tr() : 'site.design.imageNone'.tr(),
      _ => 'site.design.themeDefault'.tr(),
    };
  }

  Widget _masterList({required String? selectedId}) => _DesignMasterList(
        draft: widget.draft,
        selectedId: selectedId,
        backgroundSubtitle: _backgroundSubtitle(widget.draft),
        onSelect: _select,
      );

  Widget _detailPane(String id) {
    final resolved = siteDesignResolve(widget.draft);
    if (siteDesignBlockIsProfile(id)) return _DesignProfileDetail(draft: widget.draft);
    if (siteDesignBlockIsFeatured(id)) return UiSiteFeaturedStripDesignDetail(draft: widget.draft, itemId: id);
    if (id == 'site_product') return UiSiteProductDesignEditor(draft: widget.draft);
    if (id == 'link') return UiSiteLinkDesignEditor(draft: widget.draft);
    final block = siteDesignBlockFromItemId(id);
    if (block != null && siteDesignBlockHasCardStyle(block)) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [UiSiteBlockCardStyleEditor(draft: widget.draft, block: block)],
      );
    }
    return switch (id) {
      'theme' => _DesignThemeDetail(
          draft: widget.draft,
          searchCtrl: _themeSearchCtrl,
          search: _themeSearch,
          onSearch: (v) => setState(() => _themeSearch = v),
        ),
      'cards' => _DesignCardsDetail(draft: widget.draft, resolved: resolved),
      'background' => _DesignBackgroundDetail(draft: widget.draft, resolved: resolved),
      'backdrop' => _DesignBackdropDetail(draft: widget.draft, resolved: resolved),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.draft,
        builder: (context, _) {
          if (widget.masterDetail) {
            final selected = _activeId ?? siteDesignAppearanceIds.first;
            final cs = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final border = isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: siteCatalogMasterListW, child: _masterList(selectedId: selected)),
                ColoredBox(color: border, child: const SizedBox(width: 1)),
                Expanded(child: _detailPane(selected)),
              ],
            );
          }
          final detailId = _activeId;
          if (detailId != null) return _detailPane(detailId);
          return _masterList(selectedId: null);
        },
      );
}

class _DesignSectionHeader extends StatelessWidget {
  const _DesignSectionHeader({required this.title}) : subtitle = null;

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

class _DesignMasterList extends StatelessWidget {
  const _DesignMasterList({
    required this.draft,
    required this.selectedId,
    required this.backgroundSubtitle,
    required this.onSelect,
  });

  final SiteDesignStore draft;
  final String? selectedId;
  final String backgroundSubtitle;
  final ValueChanged<String> onSelect;

  String _blockSubtitle(String blockId) {
    if (blockId == 'profile') return siteProfileDesignSubtitle(draft.profileDesign);
    if (siteFeaturedDisplayIds.contains(blockId)) {
      return siteFeaturedStripSubtitle(draft.featuredStripGet(siteFeaturedDisplayKind(blockId)));
    }
    return siteBlockDesignSubtitle(draft.blockDesignGet(blockId), draft.cardStyle);
  }

  IconData _blockIcon(String blockId) => switch (blockId) {
        'profile' => Icons.person_outline,
        'partners_display' || 'clients_display' => Icons.view_carousel_outlined,
        _ => Icons.widgets_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final resolved = siteDesignResolve(draft);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        _DesignSectionHeader(title: 'site.design.appearance'.tr()),
        _DesignChoiceRow(
          label: 'site.design.theme'.tr(),
          value: '${siteThemeGroupName(draft.themeBaseId)}${draft.themeDark ? 'site.design.themeDark'.tr() : 'site.design.themeLight'.tr()}',
          selected: selectedId == 'theme',
          swatch: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: siteThemeSwatchGradient(draft.themeBaseId, draft.themeDark),
            ),
          ),
          onTap: () => onSelect('theme'),
        ),
        const SizedBox(height: 8),
        _DesignChoiceRow(
          label: 'site.design.cards'.tr(),
          value: siteCardStyleSubtitle(draft.cardStyle),
          selected: selectedId == 'cards',
          swatch: _CardSwatchMini(style: draft.cardStyle, theme: resolved.theme),
          onTap: () => onSelect('cards'),
          onReset: siteCardStyleIsCustom(draft.cardStyle) ? draft.cardStyleReset : null,
        ),
        const SizedBox(height: 8),
        _DesignChoiceRow(
          label: 'site.design.background'.tr(),
          value: backgroundSubtitle,
          selected: selectedId == 'background',
          icon: Icons.wallpaper_outlined,
          onTap: () => onSelect('background'),
        ),
        const SizedBox(height: 8),
        _DesignChoiceRow(
          label: 'site.design.backdrop'.tr(),
          value: siteBackdropSubtitle(draft.backdrop),
          selected: selectedId == 'backdrop',
          swatch: _BackdropSwatchMini(style: draft.backdrop, theme: resolved.theme),
          onTap: () => onSelect('backdrop'),
          onReset: siteBackdropIsCustom(draft.backdrop) ? draft.backdropReset : null,
        ),
        const SizedBox(height: 20),
        _DesignSectionHeader(title: 'site.design.blocksHeading'.tr()),
        const SizedBox(height: 4),
        for (final (id, _) in siteDesignBlockEntries) ...[
          _DesignChoiceRow(
            label: _designBlockLabelTr(id),
            value: _blockSubtitle(id),
            selected: selectedId == id,
            icon: _blockIcon(id),
            dense: true,
            onTap: () => onSelect(id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DesignChoiceRow extends StatelessWidget {
  const _DesignChoiceRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.selected = false,
    this.swatch,
    this.icon,
    this.onReset,
    this.dense = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool selected;
  final Widget? swatch;
  final IconData? icon;
  final VoidCallback? onReset;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: dense ? 0.35 : 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? cs.primary.withValues(alpha: 0.28) : cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 10 : 12),
          child: Row(
            children: [
              if (swatch != null)
                SizedBox(width: 36, height: 36, child: swatch)
              else if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: cs.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: dense ? 13 : 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (onReset != null)
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 18),
                  tooltip: 'site.design.resetPreset'.tr(),
                  onPressed: onReset,
                ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSwatchMini extends StatelessWidget {
  const _CardSwatchMini({required this.style, required this.theme});

  final SiteCardStyleDraft style;
  final SiteThemeTokens theme;

  @override
  Widget build(BuildContext context) {
    final card = siteCardDecorationResolve(style: style, theme: theme);
    return InCardStylePreview(card: card, theme: theme, dense: true);
  }
}

class _DesignThemeDetail extends StatelessWidget {
  const _DesignThemeDetail({
    required this.draft,
    required this.searchCtrl,
    required this.search,
    required this.onSearch,
  });

  final SiteDesignStore draft;
  final TextEditingController searchCtrl;
  final String search;
  final ValueChanged<String> onSearch;

  List<SiteThemeGroup> _filteredGroups() {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return siteThemeGroups;
    return siteThemeGroups.where((g) {
      final name = g.name.toLowerCase();
      final id = g.id.toLowerCase();
      if (name.contains(q) || id.contains(q)) return true;
      if (q == 'mono' && id == 'monochrome') return true;
      return false;
    }).toList();
  }

  void _clearSearch() {
    searchCtrl.clear();
    onSearch('');
  }

  void _themeModeSet(bool dark) {
    final group = siteThemeGroupGet(draft.themeBaseId);
    if (dark && !group.hasDark) return;
    if (!dark && !group.hasLight) return;
    draft.designUpdate(
      themeDark: dark,
      background: siteBackgroundAlignToTheme(draft.background, dark),
    );
  }

  void _themeSelect(SiteThemeGroup g) {
    final dark = draft.themeDark;
    final nextDark = dark ? g.hasDark || !g.hasLight : g.hasLight ? false : true;
    draft.designUpdate(
      themeBaseId: g.id,
      themeDark: nextDark,
      background: siteBackgroundAlignToTheme(draft.background, nextDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = siteThemeGroupGet(draft.themeBaseId);
    final q = search.trim();
    final groups = _filteredGroups();
    final mode = draft.themeDark && group.hasDark
        ? true
        : !draft.themeDark && group.hasLight
            ? false
            : group.hasDark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: searchCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: UiInputDecoration.of(
            context,
            floatingLabel: false,
            isDense: true,
            hintText: 'site.design.searchThemes'.tr(),
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    tooltip: 'site.design.clear'.tr(),
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close, size: 18),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: onSearch,
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text('site.design.light'.tr()),
              icon: const Icon(Icons.light_mode_outlined, size: 16),
              enabled: group.hasLight,
            ),
            ButtonSegment(
              value: true,
              label: Text('site.design.dark'.tr()),
              icon: const Icon(Icons.dark_mode_outlined, size: 16),
              enabled: group.hasDark,
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _themeModeSet(s.first),
        ),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: UINotFound(
              icon: Icons.palette_outlined,
              iconSize: 40,
              title: 'site.design.noThemesMatch'.tr(),
              subtitle: 'site.design.tryAnotherName'.tr(),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final g in groups)
                _ThemeSwatch(
                  group: g,
                  selected: g.id == draft.themeBaseId,
                  preferDark: mode,
                  onTap: () => _themeSelect(g),
                ),
            ],
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.group, required this.selected, required this.preferDark, required this.onTap});

  final SiteThemeGroup group;
  final bool selected;
  final bool preferDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: siteThemeSwatchGradient(group.id, preferDark),
                border: selected ? Border.all(color: cs.primary, width: 2) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              group.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignCardsDetail extends StatelessWidget {
  const _DesignCardsDetail({required this.draft, required this.resolved});

  final SiteDesignStore draft;
  final SiteResolvedDesign resolved;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'site.design.cardsHint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          InCardStyle(
            value: draft.cardStyle,
            theme: resolved.theme,
            onChanged: (v) => draft.designUpdate(cardStyle: v),
          ),
        ],
      );
}

class _DesignBackgroundDetail extends StatefulWidget {
  const _DesignBackgroundDetail({required this.draft, required this.resolved});

  final SiteDesignStore draft;
  final SiteResolvedDesign resolved;

  @override
  State<_DesignBackgroundDetail> createState() => _DesignBackgroundDetailState();
}

class _DesignBackgroundDetailState extends State<_DesignBackgroundDetail> {
  var _uploading = false;
  String? _error;

  Future<void> _imagePick() async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
      if (!mounted || staged == null || staged.isEmpty) return;
      final file = staged.first;
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (!mounted || up == null || up.hash.isEmpty) return;
      final bg = widget.draft.background;
      widget.draft.designUpdate(
        background: bg.copyWith(
          type: 'image',
          url: fileStoragePath(up.hash),
          overlay: bg.overlay > 0 ? bg.overlay : 0.35,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _imageClear() {
    final bg = widget.draft.background;
    widget.draft.designUpdate(background: bg.copyWith(url: '', overlay: 0));
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final bg = draft.background;
    final types = [('none', 'site.design.themeDefault'.tr()), ('color', 'site.design.solidColor'.tr()), ('image', 'site.design.image'.tr())];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('site.design.type'.tr(), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final (id, label) in types)
              ChoiceChip(
                label: Text(label),
                selected: bg.type == id,
                onSelected: (_) => draft.designUpdate(background: bg.copyWith(type: id)),
              ),
          ],
        ),
        if (bg.type == 'color') ...[
          const SizedBox(height: 16),
          InColor(
            label: 'site.design.color'.tr(),
            value: bg.color.isNotEmpty ? bg.color : siteColorFormat(widget.resolved.pageBackground),
            onChanged: (v) => draft.designUpdate(background: bg.copyWith(color: v)),
          ),
        ],
        if (bg.type == 'image') ...[
          const SizedBox(height: 16),
          Text('site.design.image'.tr(), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _BackgroundImageInput(
            url: bg.url,
            uploading: _uploading,
            onTap: _imagePick,
            onClear: bg.url.isNotEmpty ? _imageClear : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
        ],
      ],
    );
  }
}

class _BackgroundImageInput extends StatelessWidget {
  const _BackgroundImageInput({
    required this.url,
    required this.uploading,
    required this.onTap,
    this.onClear,
  });

  final String url;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = guestSitePicUrl(url).trim();
    final hasUrl = display.startsWith('http');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: uploading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              height: 140,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
                image: hasUrl
                    ? DecorationImage(image: NetworkImage(display), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!hasUrl && !uploading)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('site.design.tapUpload'.tr(), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  if (hasUrl && !uploading)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'site.design.tapChange'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  if (uploading)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: uploading ? null : onClear,
              child: Text('common.remove'.tr()),
            ),
          ),
        ],
      ],
    );
  }
}

class _BackdropSwatchMini extends StatelessWidget {
  const _BackdropSwatchMini({required this.style, required this.theme});

  final SiteBackdropDraft style;
  final SiteThemeTokens theme;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: siteBackdropPreview(style: style, theme: theme, height: 36),
      );
}

class _DesignBackdropDetail extends StatelessWidget {
  const _DesignBackdropDetail({required this.draft, required this.resolved});

  final SiteDesignStore draft;
  final SiteResolvedDesign resolved;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'site.design.backdropHint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          InBackdrop(
            value: draft.backdrop,
            theme: resolved.theme,
            onChanged: (v) => draft.designUpdate(backdrop: v),
          ),
        ],
      );
}

class _DesignProfileDetail extends StatefulWidget {
  const _DesignProfileDetail({required this.draft});

  final SiteDesignStore draft;

  @override
  State<_DesignProfileDetail> createState() => _DesignProfileDetailState();
}

class _DesignProfileDetailState extends State<_DesignProfileDetail> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  SiteProfileDesignDraft get _config => widget.draft.profileDesign;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Widget _alignChips({required String label, required String value, required ValueChanged<String> onSelect}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (id, chipLabel) in [
                ('left', 'site.design.alignLeft'.tr()),
                ('center', 'site.design.alignCenter'.tr()),
                ('right', 'site.design.alignRight'.tr()),
              ])
                ChoiceChip(
                  label: Text(chipLabel),
                  selected: value == id,
                  onSelected: (_) => onSelect(id),
                ),
            ],
          ),
        ],
      );

  Widget _fontSizeSlider({required String label, required double value, required double min, required double max, required ValueChanged<double> onChanged}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
              Text('${value.round()}px', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          Slider(value: value.clamp(min, max), min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ],
      );

  Widget _avatarTab(SiteDesignStore draft, SiteProfileDesignDraft config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fontSizeSlider(
            label: 'site.design.avatarSize'.tr(),
            value: config.avatarSize,
            min: 28,
            max: 72,
            onChanged: (v) => draft.profileDesignUpdate(avatarSize: v),
          ),
          const SizedBox(height: 8),
          _fontSizeSlider(
            label: 'site.design.outlineWidth'.tr(),
            value: config.avatarOutlineWidth,
            min: 0,
            max: 6,
            onChanged: (v) => draft.profileDesignUpdate(avatarOutlineWidth: v),
          ),
          if (config.avatarOutlineWidth > 0) ...[
            const SizedBox(height: 8),
            InColorStops(
              label: 'site.design.outlineColor'.tr(),
              value: config.avatarOutlineColor.isNotEmpty ? config.avatarOutlineColor : '#6366F1',
              onChanged: (v) => draft.profileDesignUpdate(avatarOutlineColor: v),
            ),
          ],
        ],
      );

  Widget _titleTab(SiteDesignStore draft, SiteProfileDesignDraft config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fontSizeSlider(
            label: 'site.design.fontSize'.tr(),
            value: config.titleFontSize,
            min: 14,
            max: 36,
            onChanged: (v) => draft.profileDesignUpdate(titleFontSize: v),
          ),
          const SizedBox(height: 8),
          InFont(value: config.titleFontFamily, onChanged: (v) => draft.profileDesignUpdate(titleFontFamily: v)),
          const SizedBox(height: 16),
          _alignChips(
            label: 'site.design.align'.tr(),
            value: config.titleAlign,
            onSelect: (v) => draft.profileDesignUpdate(titleAlign: v),
          ),
        ],
      );

  Widget _bioTab(SiteDesignStore draft, SiteProfileDesignDraft config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fontSizeSlider(
            label: 'site.design.fontSize'.tr(),
            value: config.bioFontSize,
            min: 10,
            max: 20,
            onChanged: (v) => draft.profileDesignUpdate(bioFontSize: v),
          ),
          const SizedBox(height: 8),
          InFont(value: config.bioFontFamily, onChanged: (v) => draft.profileDesignUpdate(bioFontFamily: v)),
          const SizedBox(height: 16),
          _alignChips(
            label: 'site.design.align'.tr(),
            value: config.bioAlign,
            onSelect: (v) => draft.profileDesignUpdate(bioAlign: v),
          ),
        ],
      );

  Widget _metaTab(SiteDesignStore draft, SiteProfileDesignDraft config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('site.design.showLocation'.tr()),
            value: config.showLocation,
            onChanged: (v) => draft.profileDesignUpdate(showLocation: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('site.design.showHours'.tr()),
            value: config.showHours,
            onChanged: (v) => draft.profileDesignUpdate(showHours: v),
          ),
        ],
      );

  Widget _hubTab(SiteDesignStore draft, SiteProfileDesignDraft config) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('site.design.catalogTabs'.tr(), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('site.design.catalogTabsHint'.tr(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Text('site.design.defaultTab'.tr(), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('site.design.shop'.tr()),
                selected: siteHubDefaultTabNormalize(config.hubDefaultTab) == 'shop',
                onSelected: (_) => draft.profileDesignUpdate(hubDefaultTab: 'shop'),
              ),
              ChoiceChip(
                label: Text('site.design.posts'.tr()),
                selected: siteHubDefaultTabNormalize(config.hubDefaultTab) == 'posts',
                onSelected: (_) => draft.profileDesignUpdate(hubDefaultTab: 'posts'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _fontSizeSlider(
            label: 'site.design.postsOnHub'.tr(),
            value: siteHubPostsPreviewLimit(config).toDouble(),
            min: 3,
            max: siteHubPostsPreviewLimitMax.toDouble(),
            onChanged: (v) => draft.profileDesignUpdate(hubPostsPreviewLimit: v.round()),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final config = _config;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: 'site.design.tabAvatar'.tr()),
            Tab(text: 'site.design.tabTitle'.tr()),
            Tab(text: 'site.design.tabBio'.tr()),
            Tab(text: 'site.design.tabMeta'.tr()),
            Tab(text: 'site.design.tabHub'.tr()),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _avatarTab(draft, config),
              _titleTab(draft, config),
              _bioTab(draft, config),
              _metaTab(draft, config),
              _hubTab(draft, config),
            ],
          ),
        ),
      ],
    );
  }
}
