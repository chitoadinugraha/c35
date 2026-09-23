import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/object.pb.dart';
import 'package:fixnum/fixnum.dart';

TableDef objectAliasTableDef() => TableDef(
      label: 'object_alias',
      primaryKey: 'id',
      columns: [
        ColDef(key: 'id', label: 'ID', readonly: true),
        ColDef(key: 'obj_path', label: 'Object', readonly: true),
        ColDef(key: 'lang', label: 'Lang'),
        ColDef(key: 'name', label: 'Name'),
        ColDef(key: 'verified', label: 'OK', type: ColType.COL_TYPE_BOOL, inlineEditable: true),
      ],
    );

Map<String, String> objectAliasCells(ObjectAliasDoc doc) => {
      'id': '${doc.id}',
      'obj_path': doc.objPath,
      'lang': doc.lang,
      'name': doc.name,
      'verified': doc.hasVerified() && doc.verified ? 'yes' : 'no',
    };

ObjectAliasDoc objectAliasFromCells(Map<String, String> cells, {ObjectAliasDoc? base}) {
  final doc = (base ?? ObjectAliasDoc()).clone();
  if (cells.containsKey('id') && cells['id']!.isNotEmpty) doc.id = Int64.parseInt(cells['id']!);
  if (cells.containsKey('lang')) doc.lang = cells['lang'] ?? '';
  if (cells.containsKey('name')) doc.name = cells['name'] ?? '';
  if (cells.containsKey('verified')) doc.verified = cells['verified']?.toLowerCase() == 'yes';
  return doc;
}
