import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:flutter_test/flutter_test.dart';

SiteEditorMenuItem _item(List<SiteEditorMenuGroup> groups, String id) {
  for (final group in groups) {
    for (final item in group.items) {
      if (item.id == id) return item;
    }
  }
  throw StateError('missing $id');
}

void main() {
  test('isPlatformSiteAlienId recognizes alienai', () {
    expect(isPlatformSiteAlienId('alienai'), isTrue);
    expect(isPlatformSiteAlienId('AlienAI'), isTrue);
    expect(isPlatformSiteAlienId('other'), isFalse);
    expect(isPlatformSiteAlienId(null), isFalse);
    expect(isPlatformSiteAlienId(''), isFalse);
  });

  test('platform site menu locks design and effects and enables contacts and posts', () {
    const caps = SiteEditorCaps(commerce: false, booking: false, queue: false);
    final groups = siteEditorMenuGroups(caps, platformSite: true);
    expect(_item(groups, 'design').enabled, isFalse);
    expect(_item(groups, 'effects').enabled, isFalse);
    expect(_item(groups, 'design').subtitle, 'Managed on the Alien AI home');
    expect(_item(groups, 'effects').subtitle, 'Managed on the Alien AI home');
    expect(_item(groups, 'contacts').enabled, isTrue);
    expect(groups.expand((g) => g.items).map((i) => i.id), contains('posts'));
    final site = groups.firstWhere((g) => g.label == 'Site');
    final ids = site.items.map((i) => i.id).toList();
    expect(ids.indexOf('posts'), ids.indexOf('links') + 1);
    expect(_item(groups, 'posts').label, 'Posts');
  });

  test('non-platform menu leaves design and effects enabled', () {
    const caps = SiteEditorCaps(commerce: false, booking: false, queue: false);
    final groups = siteEditorMenuGroups(caps, platformSite: false);
    expect(_item(groups, 'design').enabled, isTrue);
    expect(_item(groups, 'effects').enabled, isTrue);
    expect(_item(groups, 'design').subtitle, isNull);
    expect(_item(groups, 'contacts').enabled, isFalse);
  });
}
