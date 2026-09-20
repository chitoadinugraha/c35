import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:fixnum/fixnum.dart';

class AdminUserHit {
  AdminUserHit({required this.identityId, this.email = '', this.handle = '', this.name = '', this.avatarUrl = ''});
  final Int64 identityId;
  final String email;
  final String handle;
  final String name;
  final String avatarUrl;
}

class AdminApi {
  AdminApi(this.conn);
  final ReferralConn conn;

  Future<void> userPut({
    required int targetId,
    String? name,
    String? avatarUrl,
    int? referredByUid,
    bool clearReferredBy = false,
    String? handle,
    String? authEmail,
  }) async =>
      throw UnimplementedError('Admin user edit is not available in c35 Phase 1');

  Future<List<AdminUserHit>> userSearch(String query, {int limit = 20}) async => [];

  Future<bool> authEmailAvailable(String email, {int excludeId = 0}) async => true;

  Future<bool> handleAvailable(String handle, {int excludeId = 0}) async => true;
}
