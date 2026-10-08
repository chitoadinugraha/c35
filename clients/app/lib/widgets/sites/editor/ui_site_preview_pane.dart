import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_preview_stage.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _liveGreen = Color(0xFF22C55E);
const _draftGrey = Color(0xFF71717A);

/// Live guest preview for the site editor right column (CSA floorplan layout).
class UiSitePreviewPane extends StatelessWidget {
  const UiSitePreviewPane({
    super.key,
    required this.row,
    required this.api,
    required this.mode,
    required this.reloadNonce,
    this.onModeChanged,
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;
  final ValueChanged<SitePreviewMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: UiSitePreviewStage(
        headerBuilder: (context, controls) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 2),
          child: Row(
            children: [
              SitePreviewStageModeToggle(mode: controls.mode, onMode: controls.onMode),
              _VisitSiteButton(row: row, api: api, mode: mode),
              const Spacer(),
              if (onModeChanged != null) ...[
                _DraftLiveToggle(mode: mode, onChanged: onModeChanged!),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: 'Fit to screen',
                visualDensity: VisualDensity.compact,
                onPressed: controls.onRecenter,
                icon: Icon(Icons.fit_screen_outlined, size: 20, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        child: UiSitePreview(
          row: row,
          api: api,
          mode: mode,
          reloadNonce: reloadNonce,
          embedded: true,
          showVisitOverlay: false,
        ),
      ),
    );
  }
}

class _VisitSiteButton extends StatelessWidget {
  const _VisitSiteButton({required this.row, required this.api, required this.mode});

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;

  String get _slug => row.alienId.isNotEmpty ? row.alienId : row.siteIid.toString();

  Future<String> _url() async {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    if (mode == SitePreviewMode.published) return '$origin/$_slug';
    final res = await api.sitePreviewToken(row.siteIid.toInt());
    if (res.token.isEmpty) throw 'Preview token missing';
    return '$origin/$_slug?draft=1&ptoken=${Uri.encodeComponent(res.token)}';
  }

  Future<void> _open(BuildContext context) async {
    try {
      final uri = Uri.parse(await _url());
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Open in browser',
      visualDensity: VisualDensity.compact,
      onPressed: () => _open(context),
      icon: Icon(Icons.open_in_new, size: 18, color: cs.onSurfaceVariant),
    );
  }
}

class _DraftLiveToggle extends StatelessWidget {
  const _DraftLiveToggle({required this.mode, required this.onChanged});

  final SitePreviewMode mode;
  final ValueChanged<SitePreviewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DraftLiveChip(
              label: 'Draft',
              selected: mode == SitePreviewMode.draft,
              dotColor: _draftGrey,
              onTap: () => onChanged(SitePreviewMode.draft),
            ),
            _DraftLiveChip(
              label: 'Live',
              selected: mode == SitePreviewMode.published,
              dotColor: _liveGreen,
              onTap: () => onChanged(SitePreviewMode.published),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftLiveChip extends StatelessWidget {
  const _DraftLiveChip({
    required this.label,
    required this.selected,
    required this.dotColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.surfaceContainerHighest : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _text : _muted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
