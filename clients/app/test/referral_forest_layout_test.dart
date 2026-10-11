import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

ReferralTreeNode _node(int id, int parentId, {int childCount = 0}) => ReferralTreeNode(
      identityId: Int64(id),
      referredBy: Int64(parentId),
      name: 'User $id',
      childCount: childCount,
    );

void main() {
  test('collapsed branch omits children from layout height', () {
    final accounts = [
      _node(1, 0, childCount: 3),
      _node(2, 1),
      _node(3, 1),
      _node(4, 1),
    ];
    final forest = referralForestFromAccounts(accounts);
    final expanded = referralForestLayout(forest);
    final collapsed = referralForestLayout(forest, collapsedBranches: {1});

    expect(collapsed.height, lessThan(expanded.height));
    expect(collapsed.positions.containsKey(2), isFalse);
    expect(collapsed.positions.containsKey(1), isTrue);
  });

  test('referralDirectChildDisplayCount prefers server child_count when higher', () {
    final forest = referralForestFromAccounts([
      _node(1, 0, childCount: 50),
      _node(2, 1),
    ]);
    final root = forest.accountMap[1]!;
    expect(referralDirectChildDisplayCount(forest, root), 50);
  });
}
