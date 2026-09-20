import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';
import 'package:alienai_c35/c/referral/referral_shares.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_forest_canvas.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_forest_node.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_share_input.dart';
import 'package:flutter/material.dart';

class UiReferralForestController {
  UiReferralForestCanvasController? _canvasCtrl;
  ReferralForestLayout? _layout;

  void centerOnUser(int userId, {bool animate = true}) {
    final layout = _layout;
    if (layout == null) return;
    final pos = layout.positions[userId];
    if (pos != null) {
      _canvasCtrl?.centerOn(Offset(pos.x + pos.w / 2, pos.y + pos.h / 2), animate: animate);
    } else {
      _canvasCtrl?.alignCenter(animate: animate);
    }
  }

  void alignCenter({bool animate = true}) => _canvasCtrl?.alignCenter(animate: animate);

  void fitEntireTree({bool animate = true}) => _canvasCtrl?.fitToView(animate: animate);
}

class UiReferralForestChart extends StatefulWidget {
  const UiReferralForestChart({
    super.key,
    required this.nodes,
    required this.currentId,
    required this.percentages,
    this.viewerIsRoot = false,
    this.expandingId,
    this.focusId,
    this.searchMatchIds,
    this.controller,
    this.onExpand,
    this.onPercentChange,
    this.onNodeTap,
  });

  final List<ReferralTreeNode> nodes;
  final int currentId;
  final Map<String, int> percentages;
  final bool viewerIsRoot;
  final int? expandingId;
  final int? focusId;
  final Set<int>? searchMatchIds;
  final UiReferralForestController? controller;
  final ValueChanged<int>? onExpand;
  final Future<void> Function(int parentId, int childId, int value)? onPercentChange;
  final ValueChanged<ReferralTreeNode>? onNodeTap;

  static const _branchColor = Color(0xFF34D399);
  static const _card = Color(0xFF18181B);
  static const _border = Color(0xFF27272A);
  static const _accent = Color(0xFF22C55E);

  @override
  State<UiReferralForestChart> createState() => _UiReferralForestChartState();
}

class _UiReferralForestChartState extends State<UiReferralForestChart> {
  final _canvasCtrl = UiReferralForestCanvasController();

  @override
  void initState() {
    super.initState();
    widget.controller?._canvasCtrl = _canvasCtrl;
  }

  @override
  void didUpdateWidget(covariant UiReferralForestChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._canvasCtrl = null;
      widget.controller?._canvasCtrl = _canvasCtrl;
    }
  }

  @override
  void dispose() {
    widget.controller?._canvasCtrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forest = referralForestFromAccounts(widget.nodes);
    if (forest.roots.isEmpty) {
      return const Center(child: Text('No referral tree data yet', style: TextStyle(color: Color(0xFFA1A1AA))));
    }

    bool canExpand(int id) => referralCanExpandChildren(widget.nodes, forest, id);

    final layout = referralForestLayout(forest, canExpand: canExpand);
    widget.controller?._layout = layout;

    final targetId = (widget.focusId != null && widget.focusId != 0) ? widget.focusId! : widget.currentId;
    final targetPos = layout.positions[targetId] ?? layout.positions[widget.currentId];
    final initialTarget = targetPos != null ? Offset(targetPos.x + targetPos.w / 2, targetPos.y + targetPos.h / 2) : null;

    return UiReferralForestCanvas(
      controller: _canvasCtrl,
      initialTargetInChild: initialTarget,
      fixedChildSize: Size(layout.width, layout.height),
      child: _ReferralForestCanvas(
        layout: layout,
        forest: forest,
        currentId: widget.currentId,
        viewerIsRoot: widget.viewerIsRoot,
        percentages: widget.percentages,
        expandingId: widget.expandingId,
        focusId: widget.focusId,
        searchMatchIds: widget.searchMatchIds,
        canExpand: canExpand,
        onExpand: widget.onExpand,
        onPercentChange: widget.onPercentChange,
        onNodeTap: widget.onNodeTap,
      ),
    );
  }
}

class _ReferralForestCanvas extends StatelessWidget {
  const _ReferralForestCanvas({
    required this.layout,
    required this.forest,
    required this.currentId,
    required this.viewerIsRoot,
    required this.percentages,
    required this.canExpand,
    this.expandingId,
    this.focusId,
    this.searchMatchIds,
    this.onExpand,
    this.onPercentChange,
    this.onNodeTap,
  });

  final ReferralForestLayout layout;
  final ReferralForestData forest;
  final int currentId;
  final bool viewerIsRoot;
  final Map<String, int> percentages;
  final bool Function(int id) canExpand;
  final int? expandingId;
  final int? focusId;
  final Set<int>? searchMatchIds;
  final ValueChanged<int>? onExpand;
  final Future<void> Function(int parentId, int childId, int value)? onPercentChange;
  final ValueChanged<ReferralTreeNode>? onNodeTap;

  @override
  Widget build(BuildContext context) {
    final searchActive = searchMatchIds != null;
    final treeConnections = referralConnections(layout.positions, forest.childrenMap);
    final commissionConnections = referralCommissionConnections(layout.positions, forest.childrenMap);
    final branchNodeIds = referralForestDescendantIds(forest, currentId);

    bool isInBranch(int childId) => branchNodeIds.contains(childId);

    Color connectionColor(ReferralConnection conn) {
      final inBranch = viewerIsRoot || isInBranch(conn.childId);
      final base = inBranch ? UiReferralForestChart._branchColor : const Color(0xFF3F3F46);
      if (!searchActive) return base;
      final hit = searchMatchIds!.contains(conn.parentId) || searchMatchIds!.contains(conn.childId);
      return hit ? base : base.withValues(alpha: 0.12);
    }

    final commissionInBranch = commissionConnections.where((conn) {
      if (!searchActive && !viewerIsRoot) return isInBranch(conn.childId);
      if (viewerIsRoot || isInBranch(conn.childId)) return true;
      return searchActive;
    }).toList();

    int sharePercent(int parentId, int childId) => percentages[referralShareKey(parentId, childId)] ?? 0;

    double nodeOpacity(int id, bool inBranch) {
      if (!searchActive) return inBranch ? 1 : 0.4;
      if (id == focusId) return 1;
      if (searchMatchIds!.contains(id)) return 0.85;
      return 0.14;
    }

    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(layout.width, layout.height),
            painter: _ReferralEdgePainter(
              connections: treeConnections,
              colorFor: connectionColor,
              strokeWidth: 1.5,
              pathBuilder: referralConnectionPath,
            ),
          ),
          CustomPaint(
            size: Size(layout.width, layout.height),
            painter: _ReferralEdgePainter(
              connections: commissionConnections,
              colorFor: connectionColor,
              strokeWidth: 2,
              pathBuilder: referralCommissionConnectionPath,
            ),
          ),
          for (final conn in commissionInBranch)
            Positioned(
              left: conn.shareAnchor.dx - 24,
              top: conn.shareAnchor.dy - 14,
              child: Opacity(
                opacity: !searchActive || searchMatchIds!.contains(conn.parentId) || searchMatchIds!.contains(conn.childId) ? 1 : 0.14,
                child: UiReferralShareInput(
                  value: sharePercent(conn.parentId, conn.childId),
                  max: referralShareEdgeMax(conn.parentId, forest.accountMap, percentages),
                  parentId: conn.parentId,
                  childId: conn.childId,
                  accountMap: forest.accountMap,
                  percentages: percentages,
                  readonly: onPercentChange == null || (!viewerIsRoot && conn.parentId != currentId),
                  onChanged: onPercentChange == null ? null : (v) => onPercentChange!(conn.parentId, conn.childId, v),
                ),
              ),
            ),
          for (final node in layout.nodes)
            Builder(
              builder: (context) {
                final id = node.id;
                final pos = layout.positions[id]!;
                final inBranch = viewerIsRoot || branchNodeIds.contains(id);
                final isSelf = id == currentId;
                final isFocus = id == focusId;
                return Positioned(
                  left: pos.x,
                  top: pos.y,
                  width: pos.w,
                  child: Opacity(
                    opacity: nodeOpacity(id, inBranch),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: UiReferralForestChart._card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFocus
                              ? UiReferralForestChart._accent
                              : isSelf
                                  ? const Color(0xFFF4F4F5)
                                  : UiReferralForestChart._border,
                          width: isFocus || isSelf ? 2 : 1,
                        ),
                        boxShadow: isSelf || isFocus
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: pos.h),
                        child: UiReferralForestNode(
                          node: node,
                          isSelf: isSelf,
                          canExpand: canExpand(id),
                          expanding: expandingId == id,
                          remaining: referralRemainingChildCount(forest.accountMap.values.toList(), forest, id),
                          onTap: onNodeTap == null ? null : () => onNodeTap!(node),
                          onExpand: onExpand == null ? null : () => onExpand!(id),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ReferralEdgePainter extends CustomPainter {
  _ReferralEdgePainter({required this.connections, required this.colorFor, required this.strokeWidth, required this.pathBuilder});

  final List<ReferralConnection> connections;
  final Color Function(ReferralConnection conn) colorFor;
  final double strokeWidth;
  final Path Function(Offset from, Offset to) pathBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final conn in connections) {
      paint.color = colorFor(conn);
      canvas.drawPath(pathBuilder(conn.from, conn.to), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReferralEdgePainter oldDelegate) =>
      oldDelegate.connections != connections || oldDelegate.strokeWidth != strokeWidth;
}
