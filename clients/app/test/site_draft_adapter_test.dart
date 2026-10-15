import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_adapter.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

const _gucichaSiteIid = 101836119014211584;

SiteApi _dummyApi() => SiteApi(ChatConn());

final Map<String, dynamic> _gucichaFixtureDoc = {
  'pages': [
    {
      'path': '/',
      'title': 'Gucicha',
      'blocks': [
        {'id': 'product_grid1', 'type': 'product_grid', 'props': {'filter': 'all'}},
      ],
    },
  ],
  'theme': {
    'base': 'monochrome',
    'profile': {'hubDefaultTab': 'posts', 'hubPostsPreviewLimit': 6},
    'product': {'titleFontSize': 15, 'titleFontWeight': 'w600', 'priceColor': '#F4F4F5'},
  },
  'meta': {
    'catalog_display': 'grid',
    'product_design': {'titleFontSize': 15, 'titleFontWeight': 'w600', 'priceColor': '#F4F4F5'},
    'notify': {'order_ring': 'once'},
    'payment_accounts': [
      {'id': 'pa1', 'bank': 'BCA', 'account_name': 'Gucicha', 'account_number': '123', 'qris_pic': ''},
    ],
  },
};

SiteDraft _fixtureDraft() {
  return SiteDraft(
    siteIid: Int64(_gucichaSiteIid),
    doc: SiteDraftAdapter.docFromFixtureMap(_gucichaFixtureDoc),
  );
}

void main() {
  test('loads hub, notify, payment, and catalog meta from fixture', () {
    final adapter = SiteDraftAdapter.fromDraft(api: _dummyApi(), draft: _fixtureDraft());
    expect(adapter.hubDefaultTab, 'posts');
    expect(adapter.hubPostsPreviewLimit, 6);
    expect(adapter.extras.orderRing, kSiteOrderRingOnce);
    expect(adapter.extras.paymentAccounts.single.bank, 'BCA');
    expect(adapter.catalogMeta.catalogDisplay, 'grid');
  });

  test('buildDraft round-trips theme profile and product meta', () {
    final adapter = SiteDraftAdapter.fromDraft(api: _dummyApi(), draft: _fixtureDraft());
    adapter.setHubDefaultTab('shop');
    adapter.setOrderRing(kSiteOrderRingUntilHandled);
    final composed = adapter.buildDraft().doc;
    final profile = siteThemeParse(composed.themeJson)['profile'] as Map;
    expect(profile['hubDefaultTab'], 'shop');
    expect(siteDraftExtrasParse(composed.metaJson).orderRing, kSiteOrderRingUntilHandled);
    expect(siteDraftMetaParse(composed.metaJson).productDesign.titleFontWeight, 'w600');
  });

  test('round-trip preserves product meta without inventing products in doc_json', () {
    final adapter = SiteDraftAdapter.fromDraft(
      api: _dummyApi(),
      draft: _fixtureDraft(),
      products: [
        SiteProduct(productId: Int64(1001), name: 'Americano', price: Int64(28000), canSell: true),
      ],
    );
    expect(adapter.products, hasLength(1));
    final after = adapter.buildDraft();
    expect(siteDraftAdapterDocOmitsProductCatalog(after.doc), isTrue);
    expect(siteDraftJsonMap(after.doc.metaJson).containsKey('products'), isFalse);
    expect(SiteDraftAdapter.fromDraft(api: _dummyApi(), draft: after).hubDefaultTab, 'posts');
  });
}
