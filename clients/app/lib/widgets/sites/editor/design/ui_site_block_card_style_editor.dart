import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_design_resolve.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_card_style.dart';
import 'package:alienai_c35/widgets/ui/ui_dropdown_item.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

/// Per-block card style editor — shared by Design and catalog palette panes.
///
/// When [allowBare] is true (link block), offers No container / Theme cards / Custom.
class UiSiteBlockCardStyleEditor extends StatelessWidget {
  const UiSiteBlockCardStyleEditor({
    super.key,
    required this.draft,
    required this.block,
    this.allowBare = false,
  });

  final SiteDesignStore draft;
  final String block;
  final bool allowBare;

  @override
  Widget build(BuildContext context) {
    final existing = draft.blockDesignGet(block);
    final bare = existing?.isBare ?? false;
    final inherit = existing == null || existing.inheritsGlobal;
    final resolved = siteDesignResolve(draft);
    final local = inherit || bare
        ? draft.cardStyle
        : SiteCardStyleDraft(
            id: existing.cardStyleId,
            params: existing.params.isEmpty ? siteCardStyleDefaultParams(existing.cardStyleId) : existing.params,
          );

    if (allowBare) {
      final mode = bare ? 'none' : (inherit ? 'inherit' : 'custom');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('site.cardStyle.container'.tr(), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('link-container-$mode'),
            initialValue: mode,
            decoration: UiInputDecoration.of(context, labelText: 'site.cardStyle.container'.tr()),
            isExpanded: true,
            selectedItemBuilder: (context) => [
              for (final (_, icon, label) in _linkContainerOptions(context))
                UiDropdownItem(icon: icon, label: label),
            ],
            items: [
              for (final (id, icon, label) in _linkContainerOptions(context))
                DropdownMenuItem(value: id, child: UiDropdownItem(icon: icon, label: label)),
            ],
            onChanged: (v) {
              if (v == null) return;
              switch (v) {
                case 'none':
                  draft.blockDesignPut(SiteBlockDesignDraft(block: block, cardStyleId: 'none'));
                case 'inherit':
                  draft.blockDesignPut(SiteBlockDesignDraft(block: block));
                default:
                  draft.blockDesignPut(SiteBlockDesignDraft(
                    block: block,
                    cardStyleId: draft.cardStyle.id,
                    params: Map<String, num>.from(draft.cardStyle.params),
                  ));
              }
            },
          ),
          if (mode == 'custom') ...[
            const SizedBox(height: 12),
            InCardStyle(
              value: local,
              theme: resolved.theme,
              compact: true,
              onChanged: (v) => draft.blockDesignPut(
                SiteBlockDesignDraft(block: block, cardStyleId: v.id, params: v.params),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('site.cardStyle.cardStyle'.tr(), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('site.cardStyle.useGlobalCard'.tr()),
          value: inherit,
          onChanged: (v) {
            if (v) {
              draft.blockDesignPut(SiteBlockDesignDraft(block: block));
            } else {
              draft.blockDesignPut(SiteBlockDesignDraft(
                block: block,
                cardStyleId: draft.cardStyle.id,
                params: Map<String, num>.from(draft.cardStyle.params),
              ));
            }
          },
        ),
        if (!inherit) ...[
          const SizedBox(height: 8),
          InCardStyle(
            value: local,
            theme: resolved.theme,
            compact: true,
            onChanged: (v) => draft.blockDesignPut(
              SiteBlockDesignDraft(block: block, cardStyleId: v.id, params: v.params),
            ),
          ),
        ],
      ],
    );
  }
}

List<(String, IconData, String)> _linkContainerOptions(BuildContext context) => [
  ('none', Icons.crop_square_outlined, 'site.cardStyle.containerNone'.tr()),
  ('inherit', Icons.style_outlined, 'site.cardStyle.containerTheme'.tr()),
  ('custom', Icons.tune, 'site.cardStyle.containerCustom'.tr()),
];
