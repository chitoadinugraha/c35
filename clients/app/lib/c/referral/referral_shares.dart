import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';

const referralShareMaxPercent = 35;

int referralShareClamp(int value) => value.clamp(0, referralShareMaxPercent);

String referralShareKey(int parentId, int childId) => '$parentId:$childId';

class ReferralShareEdge {
  const ReferralShareEdge({required this.parentId, required this.childId, required this.sharePercent});

  final int parentId;
  final int childId;
  final int sharePercent;
}

class ReferralShareKeepRow {
  const ReferralShareKeepRow({required this.identityId, required this.displayName, required this.percent});

  final int identityId;
  final String displayName;
  final int percent;
}

int referralShareIncomingPercent(int identityId, Map<int, ReferralTreeNode> accountMap, Map<String, int> shares) {
  final parentId = accountMap[identityId]?.parentId ?? 0;
  if (parentId == 0 || !accountMap.containsKey(parentId)) return referralShareMaxPercent;
  return referralShareClamp(shares[referralShareKey(parentId, identityId)] ?? 0);
}

int referralShareEdgeMax(int parentId, Map<int, ReferralTreeNode> accountMap, Map<String, int> shares) =>
    referralShareIncomingPercent(parentId, accountMap, shares);

int referralShareClampToParent(int value, int parentIncoming) =>
    value.clamp(0, referralShareMaxPercent).clamp(0, parentIncoming);

({Map<String, int> shares, List<ReferralShareEdge> changed}) referralSharesCascadeFrom(
  ReferralForestData forest,
  Map<String, int> shares,
  int startParentId,
) {
  final next = Map<String, int>.from(shares);
  final changed = <ReferralShareEdge>[];

  void walk(int parentId) {
    final ceiling = referralShareEdgeMax(parentId, forest.accountMap, next);
    for (final child in forest.childrenMap[parentId] ?? const <ReferralTreeNode>[]) {
      final childId = child.id;
      final key = referralShareKey(parentId, childId);
      final current = next[key] ?? 0;
      final sharePercent = referralShareClampToParent(current, ceiling);
      if (sharePercent != current) {
        next[key] = sharePercent;
        changed.add(ReferralShareEdge(parentId: parentId, childId: childId, sharePercent: sharePercent));
      }
      walk(childId);
    }
  }

  walk(startParentId);
  return (shares: next, changed: changed);
}

({Map<String, int> shares, List<ReferralShareEdge> changed}) referralSharesApplyAllCeilings(
  ReferralForestData forest,
  Map<String, int> shares,
) {
  final next = Map<String, int>.from(shares);
  final changed = <ReferralShareEdge>[];

  void visit(int parentId) {
    final ceiling = referralShareEdgeMax(parentId, forest.accountMap, next);
    for (final child in forest.childrenMap[parentId] ?? const <ReferralTreeNode>[]) {
      final childId = child.id;
      final key = referralShareKey(parentId, childId);
      final current = next[key] ?? 0;
      final sharePercent = referralShareClampToParent(current, ceiling);
      if (sharePercent != current) {
        next[key] = sharePercent;
        changed.add(ReferralShareEdge(parentId: parentId, childId: childId, sharePercent: sharePercent));
      }
      visit(childId);
    }
  }

  for (final root in forest.roots) {
    visit(root.id);
  }
  return (shares: next, changed: changed);
}

({Map<String, int> shares, List<ReferralShareEdge> changed}) referralShareSet(
  ReferralForestData forest,
  Map<String, int> shares,
  int parentId,
  int childId,
  int value,
) {
  final sharePercent = referralShareClampToParent(value, referralShareEdgeMax(parentId, forest.accountMap, shares));
  final next = Map<String, int>.from(shares)..[referralShareKey(parentId, childId)] = sharePercent;
  final changed = <ReferralShareEdge>[ReferralShareEdge(parentId: parentId, childId: childId, sharePercent: sharePercent)];
  final cascaded = referralSharesCascadeFrom(forest, next, childId);
  final merged = <ReferralShareEdge>[...changed];
  for (final edge in cascaded.changed) {
    if (!merged.any((c) => c.parentId == edge.parentId && c.childId == edge.childId)) merged.add(edge);
  }
  return (shares: cascaded.shares, changed: merged);
}

({Map<String, int> shares, List<ReferralShareEdge> changed}) referralSharesFromBranchList(
  List<ReferralTreeNode> nodes,
  List<ReferralShareDoc> branchShares,
) {
  final loaded = <String, int>{};
  for (final share in branchShares) {
    loaded[referralShareKey(share.parentUid.toInt(), share.childUid.toInt())] = referralShareClamp(share.sharePercent);
  }
  return referralSharesApplyAllCeilings(referralForestFromAccounts(nodes), loaded);
}

List<ReferralShareKeepRow> referralShareKeepChain(
  int edgeParentId,
  int edgeChildId,
  int edgeValue,
  Map<int, ReferralTreeNode> accountMap,
  Map<String, int> shares,
) {
  final rows = <ReferralShareKeepRow>[];
  final childNode = accountMap[edgeChildId];
  final clampedEdge = referralShareClamp(edgeValue);
  if (childNode != null) {
    rows.add(ReferralShareKeepRow(identityId: edgeChildId, displayName: childNode.name, percent: clampedEdge));
  }
  var childId = edgeChildId;
  var parentId = edgeParentId;
  while (parentId != 0 && accountMap.containsKey(parentId)) {
    final parentNode = accountMap[parentId]!;
    final childShare = parentId == edgeParentId && childId == edgeChildId
        ? clampedEdge
        : referralShareClamp(shares[referralShareKey(parentId, childId)] ?? 0);
    final incoming = referralShareIncomingPercent(parentId, accountMap, shares);
    rows.add(ReferralShareKeepRow(
      identityId: parentId,
      displayName: parentNode.name,
      percent: (incoming - childShare).clamp(0, referralShareMaxPercent),
    ));
    childId = parentId;
    parentId = parentNode.parentId;
    if (parentId == 0 || !accountMap.containsKey(parentId)) break;
  }
  return rows;
}
