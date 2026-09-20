import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:flutter/material.dart';

Future<AdminUserHit?> referralAdminReferredByDialog(
  BuildContext context, {
  required ReferralConn conn,
  required ReferralTreeNode target,
}) async {
  if (!context.mounted) return null;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin referrer edit is not available in Phase 1')));
  return null;
}
