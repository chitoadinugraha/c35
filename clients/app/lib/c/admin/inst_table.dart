import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/inst.pb.dart';
import 'package:fixnum/fixnum.dart';

TableDef instTableDef() => TableDef(
      label: 'inst',
      primaryKey: 'id',
      columns: [
        ColDef(key: 'id', label: 'ID', readonly: true),
        ColDef(key: 'scope', label: 'Scope'),
        ColDef(key: 'kind', label: 'Kind'),
        ColDef(key: 'enabled', label: 'On', type: ColType.COL_TYPE_BOOL, inlineEditable: true),
        ColDef(key: 'priority', label: 'Pri', type: ColType.COL_TYPE_INT),
        ColDef(key: 'phrases', label: 'Phrases'),
      ],
    );

Map<String, String> instCells(InstDoc doc) => {
      'id': doc.id,
      'scope': doc.scope,
      'kind': doc.kind,
      'enabled': doc.hasEnabled() && doc.enabled ? 'yes' : 'no',
      'priority': '${doc.priority}',
      'phrases': doc.phrases.take(3).join(', '),
      '_inst': doc.inst,
      '_triggers': doc.triggers.join(', '),
      '_topic_id': doc.topicId,
    };

InstDoc instFromCells(Map<String, String> cells, {InstDoc? base}) {
  final doc = (base ?? InstDoc()).clone();
  if (cells.containsKey('id') && cells['id']!.isNotEmpty) doc.id = cells['id']!;
  if (cells.containsKey('scope')) doc.scope = cells['scope'] ?? '';
  if (cells.containsKey('kind')) doc.kind = cells['kind'] ?? '';
  if (cells.containsKey('enabled')) doc.enabled = cells['enabled']?.toLowerCase() == 'yes';
  if (cells.containsKey('priority')) doc.priority = int.tryParse(cells['priority'] ?? '') ?? doc.priority;
  if (cells.containsKey('_inst')) doc.inst = cells['_inst'] ?? doc.inst;
  if (cells.containsKey('_triggers')) {
    doc.triggers.clear();
    doc.triggers.addAll((cells['_triggers'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
  }
  if (cells.containsKey('_topic_id')) doc.topicId = cells['_topic_id'] ?? '';
  if (doc.createdTsMs <= Int64.ZERO) doc.createdTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
  doc.updatedTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
  return doc;
}
