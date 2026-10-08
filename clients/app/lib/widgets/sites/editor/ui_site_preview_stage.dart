import 'dart:math' as math;

import 'package:alienai_c35/widgets/sites/editor/ui_site_phone_preview_frame.dart';
import 'package:alienai_c35/widgets/ui/floorplan_config.dart';
import 'package:alienai_c35/widgets/ui/ui_floorplan_grid.dart';
import 'package:flutter/material.dart';

/// Pan canvas (no guest taps) vs play (guest interaction).
enum SitePreviewStageMode { pan, play }

/// Controls exposed to the preview pane header (CSA toolbar).
class SitePreviewStageControls {
  const SitePreviewStageControls({
    required this.mode,
    required this.onMode,
    required this.onRecenter,
  });

  final SitePreviewStageMode mode;
  final ValueChanged<SitePreviewStageMode> onMode;
  final VoidCallback onRecenter;
}

/// Editor preview surface — pan/pinch canvas with thin grid + centered phone (CSA).
class UiSitePreviewStage extends StatefulWidget {
  const UiSitePreviewStage({
    super.key,
    required this.child,
    this.headerBuilder,
  });

  final Widget child;
  final Widget Function(BuildContext context, SitePreviewStageControls controls)? headerBuilder;

  static const _fitPad = 20.0;
  static const fitPad = _fitPad;

  @override
  State<UiSitePreviewStage> createState() => _UiSitePreviewStageState();
}

class _UiSitePreviewStageState extends State<UiSitePreviewStage> {
  final _transformationCtrl = TransformationController();
  Size? _viewerSize;
  var _mode = SitePreviewStageMode.pan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToScreen();
    });
  }

  @override
  void dispose() {
    _transformationCtrl.dispose();
    super.dispose();
  }

  void _fitToScreen() {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.width <= 0 || viewerSize.height <= 0) return;
    final pad = UiSitePreviewStage._fitPad;
    final availW = math.max(1.0, viewerSize.width - pad * 2);
    final availH = math.max(1.0, viewerSize.height - pad * 2);
    final scale = math
        .min(availW / UiSitePhonePreviewFrame.phoneW, availH / UiSitePhonePreviewFrame.phoneH)
        .clamp(FloorplanConfig.minScale, 1.0);
    final canvasR = FloorplanConfig.canvasR;
    final dx = viewerSize.width / 2 - (canvasR + UiSitePhonePreviewFrame.phoneW / 2) * scale;
    final dy = viewerSize.height / 2 - (canvasR + UiSitePhonePreviewFrame.phoneH / 2) * scale;
    _transformationCtrl.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  SitePreviewStageControls get _controls => SitePreviewStageControls(
        mode: _mode,
        onMode: (m) => setState(() => _mode = m),
        onRecenter: _fitToScreen,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panMode = _mode == SitePreviewStageMode.pan;
    final header = widget.headerBuilder?.call(context, _controls);
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  final viewerSize = Size(viewportConstraints.maxWidth, viewportConstraints.maxHeight);
                  if (_viewerSize != viewerSize) {
                    _viewerSize = viewerSize;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitToScreen();
                    });
                  }
                  final canvasR = FloorplanConfig.canvasR;
                  return SizedBox(
                    width: viewerSize.width,
                    height: viewerSize.height,
                    child: InteractiveViewer(
                      transformationController: _transformationCtrl,
                      panEnabled: panMode,
                      scaleEnabled: true,
                      minScale: FloorplanConfig.minScale,
                      maxScale: FloorplanConfig.maxScale,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      constrained: false,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: canvasR * 2,
                        height: canvasR * 2,
                        child: Stack(
                          children: [
                            UiFloorplanGridLayer(
                              transformation: _transformationCtrl,
                              viewerSize: viewerSize,
                              colorScheme: cs,
                            ),
                            Positioned(
                              left: canvasR,
                              top: canvasR,
                              child: IgnorePointer(
                                ignoring: panMode,
                                child: UiSitePhonePreviewFrame(child: widget.child),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SitePreviewStageModeToggle extends StatelessWidget {
  const SitePreviewStageModeToggle({super.key, required this.mode, required this.onMode});

  final SitePreviewStageMode mode;
  final ValueChanged<SitePreviewStageMode> onMode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewModeChip(
              icon: Icons.visibility_outlined,
              tooltip: 'View — pan & zoom',
              selected: mode == SitePreviewStageMode.pan,
              onTap: () => onMode(SitePreviewStageMode.pan),
            ),
            _PreviewModeChip(
              icon: Icons.play_arrow_rounded,
              tooltip: 'Play — test interactions',
              selected: mode == SitePreviewStageMode.play,
              onTap: () => onMode(SitePreviewStageMode.play),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewModeChip extends StatelessWidget {
  const _PreviewModeChip({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 36,
            height: 32,
            child: Icon(icon, size: 18, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
