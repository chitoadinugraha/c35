import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/design/site_hub.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// CSA-shaped editor view over c35 [SiteDraft] + catalog RPC rows (not embedded in doc_json).
class SiteDraftAdapter extends ChangeNotifier {
  SiteDraftAdapter._({
    required this.api,
    required SiteDraft baseline,
    required this.design,
    required this.extras,
    required this.catalogMeta,
    required Map<String, bool> capabilities,
    SiteEditorCatalogCache? catalog,
    Map<int, SiteProduct>? productsById,
  })  : _baseline = baseline.clone(),
        _capabilities = Map<String, bool>.from(capabilities),
        _catalog = catalog,
        _productsById = productsById ?? {} {
    design.addListener(_onDesignChanged);
  }

  final SiteApi api;
  final SiteDesignStore design;
  SiteDraftExtras extras;
  SiteDraftMeta catalogMeta;

  SiteEditorCatalogCache? _catalog;
  SiteDraft _baseline;
  final Map<String, bool> _capabilities;
  final Map<int, SiteProduct> _productsById;

  var _docDirty = false;
  var _capabilitiesDirty = false;
  final Set<int> _dirtyProductIds = {};

  int get siteIid => _baseline.siteIid.toInt();
  SiteDoc get doc => _baseline.doc;

  String get hubDefaultTab => siteHubDefaultTabNormalize(design.profileDesign.hubDefaultTab);
  int get hubPostsPreviewLimit => design.profileDesign.hubPostsPreviewLimit;

  Map<String, bool> get capabilities => Map.unmodifiable(_capabilities);

  List<SiteProduct> get products {
    if (_catalog != null && _catalog!.warmDone) return _catalog!.products;
    return _productsById.values.toList(growable: false);
  }

  List<SiteLink> get links => _catalog?.links ?? const [];
  List<SitePost> get posts => _catalog?.posts ?? const [];
  List<SiteContact> get contacts => _catalog?.contacts ?? const [];
  List<SiteObject> get objects => _catalog?.objects ?? const [];

  bool get hasPendingFlush => _docDirty || _capabilitiesDirty || _dirtyProductIds.isNotEmpty;

  static Future<SiteDraftAdapter> load({
    required SiteApi api,
    required int siteIid,
    SiteEditorCatalogCache? catalog,
  }) async {
    final res = await api.draftGetWithPublishStatus(siteIid);
    if (!res.hasDraft()) throw 'site draft not found';
    final config = res.hasConfig() ? res.config : await api.configGet(siteIid);
    final cache = catalog ?? SiteEditorCatalogCache(api: api, siteIid: siteIid);
    if (!cache.warmDone) await cache.ensureWarm();
    return fromDraft(
      api: api,
      draft: res.draft,
      capabilitiesJson: config.capabilitiesJson,
      catalog: cache,
    );
  }

  static SiteDraftAdapter fromDraft({
    required SiteApi api,
    required SiteDraft draft,
    String capabilitiesJson = '',
    SiteEditorCatalogCache? catalog,
    Iterable<SiteProduct>? products,
  }) {
    final parsedMeta = siteDraftMetaParse(draft.doc.metaJson);
    final parsedExtras = siteDraftExtrasParse(draft.doc.metaJson);
    final store = SiteDesignStore();
    store.loadTheme(draft.doc.themeJson, productFallback: parsedMeta.productDesign);
    final byId = <int, SiteProduct>{};
    if (products != null) {
      for (final p in products) {
        byId[p.productId.toInt()] = p;
      }
    } else if (catalog != null && catalog.warmDone) {
      for (final p in catalog.products) {
        byId[p.productId.toInt()] = p;
      }
    }
    return SiteDraftAdapter._(
      api: api,
      baseline: draft,
      design: store,
      extras: parsedExtras,
      catalogMeta: parsedMeta,
      capabilities: siteCapabilitiesParse(capabilitiesJson),
      catalog: catalog,
      productsById: byId,
    );
  }

  @visibleForTesting
  static SiteDoc docFromFixtureMap(Map<String, dynamic> json) => _docFromFixtureMap(json);

  void setHubDefaultTab(String tab) => design.profileDesignUpdate(hubDefaultTab: tab);

  void setHubPostsPreviewLimit(int limit) => design.profileDesignUpdate(hubPostsPreviewLimit: limit);

  void setOrderRing(String ring) {
    extras = SiteDraftExtras(
      knowledge: extras.knowledge,
      orderRing: siteOrderRingNormalize(ring),
      paymentAccounts: extras.paymentAccounts,
      aiAssistant: extras.aiAssistant,
    );
    _markDocDirty();
  }

  void setPaymentAccounts(List<SitePaymentAccountDraft> accounts) {
    extras = SiteDraftExtras(
      knowledge: extras.knowledge,
      orderRing: extras.orderRing,
      paymentAccounts: accounts,
      aiAssistant: extras.aiAssistant,
    );
    _markDocDirty();
  }

  void setKnowledgeAndAi({
    List<SiteKnowledgeDraft>? knowledge,
    SiteAiAssistantDraft? aiAssistant,
  }) {
    extras = SiteDraftExtras(
      knowledge: knowledge ?? extras.knowledge,
      orderRing: extras.orderRing,
      paymentAccounts: extras.paymentAccounts,
      aiAssistant: aiAssistant ?? extras.aiAssistant,
    );
    _markDocDirty();
  }

  /// After an immediate productPut, keep catalog in sync without a second RPC on flush.
  void adoptProduct(SiteProduct product) {
    final id = product.productId.toInt();
    _productsById[id] = product;
    _dirtyProductIds.remove(id);
    _catalog?.upsertProduct(product);
    notifyListeners();
  }

  /// Reload from server when another editor path saved the draft (no local dirty state).
  void replaceBaseline(SiteDraft draft) {
    if (_docDirty || _capabilitiesDirty || _dirtyProductIds.isNotEmpty) return;
    _baseline = draft.clone();
    final parsedMeta = siteDraftMetaParse(draft.doc.metaJson);
    extras = siteDraftExtrasParse(draft.doc.metaJson);
    catalogMeta = parsedMeta;
    design.loadTheme(draft.doc.themeJson, productFallback: parsedMeta.productDesign);
    notifyListeners();
  }

  void setCatalogMeta(SiteDraftMeta next) {
    catalogMeta = next;
    _markDocDirty();
  }

  void setCapabilities(Map<String, bool> next) {
    _capabilities..clear()..addAll(next);
    _capabilitiesDirty = true;
    notifyListeners();
  }

  void upsertProduct(SiteProduct product) {
    final id = product.productId.toInt();
    _productsById[id] = product;
    _dirtyProductIds.add(id);
    _catalog?.upsertProduct(product);
    notifyListeners();
  }

  SiteDraft buildDraft() => composeDraftPut();

  SiteDraft composeDraftPut() {
    final out = _baseline.clone();
    out.doc = _composeDoc(_baseline.doc);
    return out;
  }

  Future<void> flush({bool skipPublish = false}) async {
    if (_docDirty) {
      final saved = await api.draftPut(composeDraftPut(), skipPublish: skipPublish);
      _baseline = saved.clone();
      _docDirty = false;
    }
    if (_capabilitiesDirty) {
      await api.configPut(siteIid, capabilitiesJson: siteCapabilitiesEncode(_capabilities));
      _capabilitiesDirty = false;
    }
    for (final id in List<int>.from(_dirtyProductIds)) {
      final product = _productsById[id];
      if (product == null) {
        _dirtyProductIds.remove(id);
        continue;
      }
      final saved = await api.productPut(siteIid, product);
      _productsById[id] = saved;
      _catalog?.upsertProduct(saved);
      _dirtyProductIds.remove(id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    design.removeListener(_onDesignChanged);
    super.dispose();
  }

  void _onDesignChanged() => _markDocDirty();

  void _markDocDirty() {
    if (_docDirty) return;
    _docDirty = true;
    notifyListeners();
  }

  SiteDoc _composeDoc(SiteDoc base) {
    final doc = base.clone();
    doc.themeJson = design.toThemeJson();
    var meta = doc.metaJson;
    meta = siteDraftMetaMerge(
      meta,
      taxes: catalogMeta.taxes,
      productDesign: design.productDesign,
      catalogDisplay: catalogMeta.catalogDisplay,
    );
    meta = siteDraftExtrasMerge(
      meta,
      knowledge: extras.knowledge,
      orderRing: extras.orderRing,
      paymentAccounts: extras.paymentAccounts,
      aiAssistant: extras.aiAssistant,
    );
    doc.metaJson = meta;
    return doc;
  }
}

@visibleForTesting
bool siteDraftAdapterDocOmitsProductCatalog(SiteDoc doc) {
  if (siteDraftJsonMap(doc.metaJson).containsKey('products')) return false;
  for (final page in doc.pages) {
    for (final block in page.blocks) {
      if (siteDraftJsonMap(block.propsJson).containsKey('products')) return false;
    }
  }
  return true;
}

SiteDoc _docFromFixtureMap(Map<String, dynamic> json) {
  final pages = <SitePage>[];
  final pagesRaw = json['pages'];
  if (pagesRaw is List) {
    for (final p in pagesRaw) {
      if (p is! Map) continue;
      final m = p.map((k, v) => MapEntry(k.toString(), v));
      final blocks = <SiteBlock>[];
      final blocksRaw = m['blocks'];
      if (blocksRaw is List) {
        for (final b in blocksRaw) {
          if (b is! Map) continue;
          final bm = b.map((k, v) => MapEntry(k.toString(), v));
          final props = bm['props'];
          blocks.add(SiteBlock(
            id: bm['id']?.toString() ?? '',
            type: bm['type']?.toString() ?? '',
            propsJson: jsonEncode(props is Map ? props : {}),
          ));
        }
      }
      pages.add(SitePage(
        path: m['path']?.toString() ?? '/',
        title: m['title']?.toString() ?? '',
        blocks: blocks,
      ));
    }
  }
  return SiteDoc(
    pages: pages,
    themeJson: jsonEncode(json['theme'] is Map ? json['theme'] : {}),
    metaJson: jsonEncode(json['meta'] is Map ? json['meta'] : {}),
  );
}
