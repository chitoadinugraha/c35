import 'dart:convert';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/c/pb/c35/consumption.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

class ConsumptionApi {
  ConsumptionApi({ReferralConn? conn}) : _conn = conn ?? ReferralConn();

  final ReferralConn _conn;

  Future<Map<String, dynamic>> update({required int consumptionId, required List<ConsumptionItemRow> items, String locale = 'en-US'}) async {
    final res = await _conn.invoke(
      InvokeReq(
        reqId: const Uuid().v4(),
        consumptionPut: ReqConsumptionPut(
          consumption: Consumption(
            id: Int64(consumptionId),
            items: items
                .map(
                  (e) => ConsumptionItem(
                    name: e.name,
                    nameId: e.nameId,
                    qty: e.qty,
                    nutrition: Nutrition(
                      calories: e.calories,
                      protein: e.protein,
                      fat: e.fat,
                      carbs: e.carbs,
                      fiber: e.fiber,
                      sugar: e.sugar,
                      sodium: e.sodium,
                      potassium: e.potassium,
                      iron: e.iron,
                      cholesterol: e.cholesterol,
                      purines: e.purines,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    invokeResThrow(res, fallback: 'consumption update failed');
    if (!res.hasConsumptionPut()) return const {};
    final put = res.consumptionPut;
    final raw = put.blocksJson.trim();
    if (raw.isEmpty || raw == '[]') return const {};
    final arr = jsonDecode(raw) as List<dynamic>;
    if (arr.isEmpty) return const {};
    final block = arr.first;
    if (block is Map<String, dynamic>) return {'block': block};
    return {'block': Map<String, dynamic>.from(block as Map)};
  }

  Future<bool> delete({required int consumptionId}) async {
    final res = await _conn.invoke(
      InvokeReq(
        reqId: const Uuid().v4(),
        consumptionPut: ReqConsumptionPut(
          consumption: Consumption(
            id: Int64(consumptionId),
            deletedTsMs: Int64(DateTime.now().millisecondsSinceEpoch),
          ),
        ),
      ),
    );
    invokeResThrow(res, fallback: 'consumption delete failed');
    return true;
  }
}
