import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:flutter_test/flutter_test.dart';

SiteObject obj(String name, String kind) => SiteObject()
  ..name = name
  ..kind = kind;

void main() {
  test('prefix strips a trailing number', () {
    expect(siteObjectNamePrefix('Villa 01'), 'Villa');
    expect(siteObjectNamePrefix('Table-12'), 'Table');
    expect(siteObjectNamePrefix('Lobby'), 'Lobby');
    expect(siteObjectNamePrefix('  '), 'Other');
  });

  test('groups kind then prefix', () {
    final groups = siteObjectsGroupByKindPrefix([
      obj('Villa 2', siteObjectKindRoom),
      obj('Meja 1', siteObjectKindTable),
      obj('Villa 1', siteObjectKindRoom),
    ]);
    expect(groups.map((g) => g.kind).toList(), [siteObjectKindRoom, siteObjectKindTable]);
    expect(groups.first.prefixes.single.prefix, 'Villa');
    expect(groups.first.prefixes.single.objs.map((o) => o.name).toList(), ['Villa 2', 'Villa 1']);
  });
}
