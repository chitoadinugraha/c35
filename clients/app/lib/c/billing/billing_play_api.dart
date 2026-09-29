import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingPlayProductList> billingPlayProductList(ReferralConn conn) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingPlayProductList: ReqBillingPlayProductList()),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load Play products');
  if (!res.hasBillingPlayProductList()) throw 'No Play product list response';
  return res.billingPlayProductList;
}

Future<ResBillingPlayVerify> billingPlayVerify(
  ReferralConn conn, {
  required String productId,
  required String purchaseToken,
  String packageName = '',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingPlayVerify: ReqBillingPlayVerify(
        productId: productId,
        purchaseToken: purchaseToken,
        packageName: packageName,
      ),
    ),
    timeout: const Duration(seconds: 45),
  );
  invokeResThrow(res, fallback: 'Failed to verify Play purchase');
  if (!res.hasBillingPlayVerify()) throw 'No Play verify response';
  return res.billingPlayVerify;
}
