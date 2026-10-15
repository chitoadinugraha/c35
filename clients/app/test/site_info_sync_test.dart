import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_info_sync.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('siteInfoApplyToDoc syncs hub_profile and hours block', () {
    final doc = SiteDoc(
      pages: [
        SitePage(
          path: '/',
          title: 'Shop',
          blocks: [
            SiteBlock(
              id: 'hub1',
              type: 'hub_profile',
              propsJson: '{"title":"Old","subtitle":"old sub"}',
            ),
          ],
        ),
      ],
      metaJson: '{}',
    );
    final slot = SiteScheduleSlot(id: 's1', startDay: 0, startMin: 540, endDay: 0, endMin: 1020);
    final out = siteInfoApplyToDoc(
      doc,
      SiteInfoSnapshot(
        name: 'Warung',
        tagline: 'Fresh food daily',
        pic: 'pic1',
        locationLabel: 'Malang',
        locationHref: 'https://maps.example/malang',
        primaryColor: '#3366FF',
        openHours: [slot],
      ),
    );
    expect(out.metaJson, contains('Fresh food daily'));
    final hub = out.pages.first.blocks.firstWhere((b) => b.type == 'hub_profile');
    expect(hub.propsJson, contains('Warung'));
    expect(hub.propsJson, contains('Fresh food daily'));
    expect(hub.propsJson, contains('Malang'));
    final hours = out.pages.first.blocks.where((b) => b.type == 'hours').toList();
    expect(hours.length, 1);
    expect(hours.first.propsJson, contains('schedule'));
  });

  test('siteMetaTaglineRead prefers tagline over seo_desc', () {
    expect(siteMetaTaglineRead('{"tagline":"a","seo_desc":"b"}'), 'a');
    expect(siteMetaTaglineRead('{"seo_desc":"b"}'), 'b');
  });

  test('siteMetaPrimaryColorRead and merge', () {
    expect(siteMetaPrimaryColorRead('{}'), '#F97316');
    expect(siteMetaPrimaryColorRead('{"primary_color":"#3366FF"}'), '#3366FF');
    final merged = siteMetaMergeInfo('{}', primaryColor: '#3366FF');
    expect(merged, contains('3366FF'));
    final defaultMerge = siteMetaMergeInfo('{"primary_color":"#3366FF"}', primaryColor: '#F97316');
    expect(defaultMerge.contains('primary_color'), isFalse);
  });
}
