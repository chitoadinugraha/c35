import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/data_source.pb.dart';
import 'package:fixnum/fixnum.dart';

Future<ResDataSourceList> dataSourceList(ChatConn conn, {int botIid = 0, int sinceUpdatedTsMs = 0, int limit = 100}) =>
    conn.dataSourceList(botIid: botIid, sinceUpdatedTsMs: sinceUpdatedTsMs, limit: limit);

Future<ResDataSourcePut> dataSourcePut(
  ChatConn conn, {
  required int botIid,
  required String sourceKind,
  required String name,
  required String configJson,
  int id = 0,
}) =>
    conn.dataSourcePut(
      DataSourceDoc(
        id: Int64(id),
        botIid: Int64(botIid),
        sourceKind: sourceKind,
        name: name,
        configJson: configJson,
      ),
    );

Future<ResDataSourceSync> dataSourceSync(ChatConn conn, int id) => conn.dataSourceSync(id);

Future<ResDataSourceCheck> dataSourceCheck(
  ChatConn conn, {
  required String sourceKind,
  required String viewUrl,
}) =>
    conn.dataSourceCheck(sourceKind: sourceKind, viewUrl: viewUrl);

Future<ResDataSourceDelete> dataSourceDelete(ChatConn conn, int id) => conn.dataSourceDelete(id);