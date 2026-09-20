import 'dart:ui';

import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:fixnum/fixnum.dart';

extension ReferralTreeNodeView on ReferralTreeNode {
  int get id => identityId.toInt();
  int get parentId => referredBy.toInt();

  String get initials {
    final n = name.trim();
    if (n.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
  }

  String get displayHandle => handle.isNotEmpty ? handle : email;
}

class ReferralForestData {
  const ReferralForestData({required this.accountMap, required this.childrenMap, required this.roots});

  final Map<int, ReferralTreeNode> accountMap;
  final Map<int, List<ReferralTreeNode>> childrenMap;
  final List<ReferralTreeNode> roots;
}

class ReferralNodePosition {
  const ReferralNodePosition({required this.x, required this.y, required this.w, required this.h});

  final double x;
  final double y;
  final double w;
  final double h;
}

class ReferralForestLayout {
  const ReferralForestLayout({required this.positions, required this.nodes, required this.width, required this.height});

  final Map<int, ReferralNodePosition> positions;
  final List<ReferralTreeNode> nodes;
  final double width;
  final double height;
}

class ReferralConnection {
  const ReferralConnection({required this.parentId, required this.childId, required this.from, required this.to, required this.shareAnchor});

  final int parentId;
  final int childId;
  final Offset from;
  final Offset to;
  final Offset shareAnchor;
}

const referralNodeWidth = 260.0;
const referralNodeMinHeight = 68.0;
const referralNodeBadgeHeight = 96.0;
const referralGraphPadding = 48.0;
const referralChildRowGap = 80.0;
const referralSiblingVPad = 16.0;
const referralBranchXFraction = 0.28;
const referralNodeExpandHeight = 36.0;

int referralRemainingChildCount(List<ReferralTreeNode> nodes, ReferralForestData forest, int parentId) {
  final node = forest.accountMap[parentId];
  if (node == null) return 0;
  final loaded = referralLoadedChildCount(nodes, parentId);
  final remaining = node.childCount - loaded;
  return remaining > 0 ? remaining : 0;
}

bool referralCanExpandChildren(List<ReferralTreeNode> nodes, ReferralForestData forest, int parentId) =>
    referralRemainingChildCount(nodes, forest, parentId) > 0;

const _legacyRootUids = {1000, 1001};
const _devRootUid = 99000;

bool referralNodeIsRoot(ReferralTreeNode node) {
  if (node.isRoot) return true;
  if (node.id == _devRootUid) return true;
  final h = node.handle.trim().toLowerCase().replaceAll('@', '');
  return h == 'chito' || h == 'chitoadinugraha';
}

bool referralTreeWideAccess({required int viewerId, required List<ReferralTreeNode> nodes}) {
  if (sessionViewerIsRoot()) return true;
  if (viewerId == _devRootUid) return true;
  for (final n in nodes) {
    if (n.id != viewerId) continue;
    if (referralNodeIsRoot(n)) return true;
    if (n.globalRoles.contains('partner')) return true;
  }
  return false;
}

ReferralTreeNode referralTreeNodeWithParent(ReferralTreeNode node, int referredBy) {
  if (node.parentId == referredBy) return node;
  return (ReferralTreeNode()..mergeFromMessage(node))..referredBy = Int64(referredBy);
}

int referralLoadedChildCount(List<ReferralTreeNode> nodes, int parentId) =>
    nodes.where((n) => n.parentId == parentId).length;

List<ReferralTreeNode> referralForestSanitizedAccounts(List<ReferralTreeNode> accounts) {
  if (accounts.isEmpty) return accounts;
  final map = {for (final u in accounts) u.id: u};
  final parent = <int, int>{};
  for (final u in accounts) {
    final raw = u.parentId;
    parent[u.id] = raw != 0 && raw != u.id ? raw : 0;
  }
  final sorted = List<ReferralTreeNode>.from(accounts)..sort((a, b) => a.id.compareTo(b.id));
  for (final u in sorted) {
    final id = u.id;
    final p = parent[id] ?? 0;
    if (p == 0 || !map.containsKey(p)) continue;
    final seen = <int>{id};
    var cur = p;
    while (true) {
      if (!seen.add(cur)) {
        parent[id] = 0;
        break;
      }
      final next = parent[cur] ?? 0;
      if (next == 0 || next == cur || !map.containsKey(next)) break;
      cur = next;
    }
  }
  return accounts.map((u) => referralTreeNodeWithParent(u, parent[u.id] ?? 0)).toList();
}

List<ReferralTreeNode> referralForestRemapLegacyRoots(List<ReferralTreeNode> accounts) {
  if (accounts.isEmpty) return accounts;
  final map = {for (final u in accounts) u.id: u};
  final rootId = accounts.where(referralNodeIsRoot).map((u) => u.id).fold<int?>(null, (best, id) => best == null || id < best ? id : best);
  if (rootId == null) return accounts;
  return accounts.map((u) {
    final raw = u.parentId;
    if (raw == 0 || map.containsKey(raw) || !_legacyRootUids.contains(raw)) return u;
    return referralTreeNodeWithParent(u, rootId);
  }).toList();
}

ReferralForestData referralForestFromAccounts(List<ReferralTreeNode> accounts) {
  final sanitized = referralForestSanitizedAccounts(referralForestRemapLegacyRoots(accounts));
  final accountMap = {for (final u in sanitized) u.id: u};
  final childrenMap = <int, List<ReferralTreeNode>>{};
  for (final u in sanitized) {
    final p = u.parentId;
    if (p != 0 && accountMap.containsKey(p)) childrenMap.putIfAbsent(p, () => []).add(u);
  }
  final seen = <int>{};
  final roots = <ReferralTreeNode>[];
  for (final u in sanitized) {
    final p = u.parentId;
    if ((p == 0 || !accountMap.containsKey(p)) && seen.add(u.id)) roots.add(u);
  }
  roots.sort((a, b) {
    if (referralNodeIsRoot(a) != referralNodeIsRoot(b)) return referralNodeIsRoot(a) ? -1 : 1;
    final kids = b.childCount.compareTo(a.childCount);
    if (kids != 0) return kids;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  for (final kids in childrenMap.values) {
    kids.sort((a, b) => a.name.compareTo(b.name));
  }
  return ReferralForestData(accountMap: accountMap, childrenMap: childrenMap, roots: roots);
}

Set<int> referralForestDescendantIds(ReferralForestData forest, int rootId) {
  final out = <int>{};
  void walk(int id) {
    if (!forest.accountMap.containsKey(id) || !out.add(id)) return;
    for (final child in forest.childrenMap[id] ?? const <ReferralTreeNode>[]) {
      walk(child.id);
    }
  }

  walk(rootId);
  return out;
}

double referralNodeLayoutHeight(ReferralTreeNode node, {bool canExpand = false}) {
  var h = referralNodeMinHeight;
  if (referralNodeIsRoot(node) || node.globalRoles.isNotEmpty) h += referralNodeBadgeHeight - referralNodeMinHeight;
  if (canExpand) h += referralNodeExpandHeight;
  return h;
}

ReferralForestLayout referralForestLayout(ReferralForestData forest, {bool Function(int nodeId)? canExpand}) {
  final positions = <int, ReferralNodePosition>{};
  final nodes = <ReferralTreeNode>[];
  var maxX = 0.0;
  var maxY = 0.0;
  const pad = referralGraphPadding;

  void trackBounds(double x, double y, double w, double h) {
    maxX = maxX < x + w ? x + w : maxX;
    maxY = maxY < y + h ? y + h : maxY;
  }

  void placeNode(ReferralTreeNode node, double x, double y, {required bool expand}) {
    final h = referralNodeLayoutHeight(node, canExpand: expand);
    positions[node.id] = ReferralNodePosition(x: x, y: y, w: referralNodeWidth, h: h);
    nodes.add(node);
    trackBounds(x, y, referralNodeWidth, h);
  }

  double layoutNode(ReferralTreeNode account, double x, double y, Set<int> visited) {
    final id = account.id;
    final expand = canExpand?.call(id) ?? false;
    final nodeH = referralNodeLayoutHeight(account, canExpand: expand);
    if (visited.contains(id)) {
      placeNode(account, x, y, expand: expand);
      return nodeH;
    }
    final kids = forest.childrenMap[id] ?? const <ReferralTreeNode>[];
    final nextVisited = {...visited, id};
    if (kids.isEmpty) {
      placeNode(account, x, y, expand: expand);
      return nodeH;
    }
    final childX = x + referralNodeWidth + referralChildRowGap;
    var childY = y;
    var childrenHeight = 0.0;
    for (var i = 0; i < kids.length; i++) {
      if (i > 0) {
        childY += referralSiblingVPad;
        childrenHeight += referralSiblingVPad;
      }
      final subH = layoutNode(kids[i], childX, childY, nextVisited);
      childY += subH;
      childrenHeight += subH;
    }
    placeNode(account, x, y + (childrenHeight > nodeH ? (childrenHeight - nodeH) / 2 : 0), expand: expand);
    return childrenHeight > nodeH ? childrenHeight : nodeH;
  }

  var rootY = pad;
  for (var i = 0; i < forest.roots.length; i++) {
    if (i > 0) rootY += referralSiblingVPad;
    rootY += layoutNode(forest.roots[i], pad, rootY, {});
  }

  return ReferralForestLayout(
    positions: positions,
    nodes: nodes,
    width: (maxX + pad) > pad * 2 ? maxX + pad : pad * 2,
    height: (maxY + pad) > pad * 2 ? maxY + pad : pad * 2,
  );
}

Offset referralConnectionShareAnchor(Offset from, Offset to, [double branchFraction = referralBranchXFraction]) {
  final branchX = from.dx + (to.dx - from.dx) * branchFraction;
  return Offset((branchX + to.dx) / 2, to.dy);
}

Offset referralCommissionShareAnchor(Offset from, Offset to, [double branchFraction = referralBranchXFraction]) {
  final branchX = to.dx + (from.dx - to.dx) * branchFraction;
  return Offset((from.dx + branchX) / 2, from.dy);
}

Path referralCommissionConnectionPath(Offset from, Offset to, [double branchFraction = referralBranchXFraction]) {
  final branchX = to.dx + (from.dx - to.dx) * branchFraction;
  return Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(branchX, from.dy)
    ..lineTo(branchX, to.dy)
    ..lineTo(to.dx, to.dy);
}

Path referralConnectionPath(Offset from, Offset to, [double branchFraction = referralBranchXFraction]) {
  final branchX = from.dx + (to.dx - from.dx) * branchFraction;
  return Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(branchX, from.dy)
    ..lineTo(branchX, to.dy)
    ..lineTo(to.dx, to.dy);
}

List<ReferralConnection> referralCommissionConnections(
  Map<int, ReferralNodePosition> nodePositions,
  Map<int, List<ReferralTreeNode>> childrenMap,
) {
  final out = <ReferralConnection>[];
  for (final entry in childrenMap.entries) {
    final parentPos = nodePositions[entry.key];
    if (parentPos == null) continue;
    for (final ch in entry.value) {
      final childPos = nodePositions[ch.id];
      if (childPos == null) continue;
      final from = Offset(childPos.x, childPos.y + childPos.h / 2);
      final to = Offset(parentPos.x + parentPos.w, parentPos.y + parentPos.h / 2);
      out.add(ReferralConnection(parentId: entry.key, childId: ch.id, from: from, to: to, shareAnchor: referralCommissionShareAnchor(from, to)));
    }
  }
  return out;
}

List<ReferralConnection> referralExpandConnections(
  Map<int, ReferralNodePosition> nodePositions,
  Map<int, ReferralNodePosition> expandPositions,
) =>
    const [];

List<ReferralConnection> referralConnections(
  Map<int, ReferralNodePosition> nodePositions,
  Map<int, List<ReferralTreeNode>> childrenMap,
) {
  final out = <ReferralConnection>[];
  for (final entry in childrenMap.entries) {
    final parentPos = nodePositions[entry.key];
    if (parentPos == null) continue;
    for (final ch in entry.value) {
      final childPos = nodePositions[ch.id];
      if (childPos == null) continue;
      final from = Offset(parentPos.x + parentPos.w, parentPos.y + parentPos.h / 2);
      final to = Offset(childPos.x, childPos.y + childPos.h / 2);
      out.add(ReferralConnection(parentId: entry.key, childId: ch.id, from: from, to: to, shareAnchor: referralConnectionShareAnchor(from, to)));
    }
  }
  return out;
}

ReferralTreeSlice referralTreeSliceMerge(ReferralTreeSlice base, ReferralTreeSlice incoming) {
  final seen = {for (final n in base.nodes) n.id};
  final nodes = [...base.nodes];
  for (final node in incoming.nodes) {
    if (seen.add(node.id)) nodes.add(node);
  }
  final shareSeen = {for (final s in base.branchShares) '${s.parentUid.toInt()}:${s.childUid.toInt()}'};
  final shares = [...base.branchShares];
  for (final share in incoming.branchShares) {
    if (shareSeen.add('${share.parentUid.toInt()}:${share.childUid.toInt()}')) shares.add(share);
  }
  return ReferralTreeSlice(nodes: nodes, branchShares: shares);
}
