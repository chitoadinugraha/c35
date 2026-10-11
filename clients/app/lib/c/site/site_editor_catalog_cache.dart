import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:flutter/foundation.dart';

/// Shared catalog rows for the site editor — warmed once on shell open.
class SiteEditorCatalogCache extends ChangeNotifier {
  SiteEditorCatalogCache({required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  var warmDone = false;
  var warming = false;
  String? warmError;

  final _linksById = <String, SiteLink>{};
  final _contactsById = <String, SiteContact>{};
  final _postsById = <String, SitePost>{};
  final _objectsById = <String, SiteObject>{};
  final _productsById = <String, SiteProduct>{};
  var _grants = <SiteGrant>[];
  var _queues = <SiteQueue>[];
  var _workShifts = <SiteWorkShift>[];

  var productNextCursor = '';
  var productHasMore = false;
  var productLoadingMore = false;
  var productLoadingAll = false;

  Future<void>? _warmFuture;
  var _disposed = false;

  List<SiteLink> get links => _linksById.values.toList(growable: false);
  List<SiteContact> get contacts => _contactsById.values.toList(growable: false);
  List<SitePost> get posts => _postsById.values.toList(growable: false);
  List<SiteObject> get objects => _objectsById.values.toList(growable: false);
  List<SiteProduct> get products => _productsById.values.toList(growable: false);
  List<SiteGrant> get grants => List<SiteGrant>.from(_grants);
  List<SiteQueue> get queues => List<SiteQueue>.from(_queues);
  List<SiteWorkShift> get workShifts => List<SiteWorkShift>.from(_workShifts);

  SiteQueue? get primaryQueue => _queues.isEmpty ? null : _queues.first;

  Future<void> warm() => ensureWarm();

  Future<void> ensureWarm() {
    if (_disposed) return Future<void>.value();
    if (warmDone) return Future<void>.value();
    _warmFuture ??= _runWarm();
    return _warmFuture!;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<void> _runWarm() async {
    if (_disposed || warming) return;
    warming = true;
    warmError = null;
    notifyListeners();
    try {
      final res = await api.editorWarm(siteIid);
      _linksById
        ..clear()
        ..addEntries(res.links.map((l) => MapEntry('${l.linkId}', l)));
      _contactsById
        ..clear()
        ..addEntries(res.contacts.map((c) => MapEntry('${c.contactId}', c)));
      _postsById
        ..clear()
        ..addEntries(res.posts.map((p) => MapEntry('${p.postId}', p)));
      _objectsById
        ..clear()
        ..addEntries(res.objs.map((o) => MapEntry('${o.id}', o)));
      _productsById.clear();
      _mergeProducts(res.products);
      productNextCursor = res.productNextCursor;
      productHasMore = res.productHasMore;
      _grants = List<SiteGrant>.from(res.grants);
      _queues = List<SiteQueue>.from(res.queues);
      _workShifts = List<SiteWorkShift>.from(res.workShifts);
      warmDone = true;
    } catch (e) {
      warmError = '$e';
    } finally {
      if (!_disposed) {
        warming = false;
        notifyListeners();
      }
    }
  }

  void _mergeProducts(List<SiteProduct> items, {bool replace = false}) {
    if (replace) _productsById.clear();
    for (final p in items) {
      _productsById['${p.productId}'] = p;
    }
  }

  Future<void> loadMoreProducts() async {
    if (!productHasMore || productLoadingMore || productNextCursor.isEmpty) return;
    productLoadingMore = true;
    notifyListeners();
    try {
      final page = await api.productListPage(siteIid, cursor: productNextCursor);
      _mergeProducts(page.products);
      productNextCursor = page.nextCursor;
      productHasMore = page.hasMore;
    } catch (e) {
      warmError = '$e';
    } finally {
      productLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> ensureAllProducts() async {
    if (!productHasMore || productLoadingAll) return;
    productLoadingAll = true;
    notifyListeners();
    try {
      while (productHasMore && productNextCursor.isNotEmpty) {
        await loadMoreProducts();
      }
      if (productHasMore) {
        final items = await api.productList(siteIid);
        _mergeProducts(items, replace: true);
        productHasMore = false;
        productNextCursor = '';
      }
    } catch (e) {
      warmError = '$e';
    } finally {
      productLoadingAll = false;
      notifyListeners();
    }
  }

  void upsertLink(SiteLink link) {
    _linksById['${link.linkId}'] = link;
    notifyListeners();
  }

  void removeLink(int linkId) {
    _linksById.remove('$linkId');
    notifyListeners();
  }

  void setLinks(List<SiteLink> items) {
    _linksById
      ..clear()
      ..addEntries(items.map((l) => MapEntry('${l.linkId}', l)));
    notifyListeners();
  }

  void upsertContact(SiteContact contact) {
    _contactsById['${contact.contactId}'] = contact;
    notifyListeners();
  }

  void removeContact(int contactId) {
    _contactsById.remove('$contactId');
    notifyListeners();
  }

  void upsertPost(SitePost post) {
    _postsById['${post.postId}'] = post;
    notifyListeners();
  }

  void removePost(int postId) {
    _postsById.remove('$postId');
    notifyListeners();
  }

  void upsertObject(SiteObject obj) {
    _objectsById['${obj.id}'] = obj;
    notifyListeners();
  }

  void removeObject(int id) {
    _objectsById.remove('$id');
    notifyListeners();
  }

  void upsertProduct(SiteProduct product) {
    _productsById['${product.productId}'] = product;
    notifyListeners();
  }

  void removeProduct(int productId) {
    _productsById.remove('$productId');
    notifyListeners();
  }

  void replaceProducts(List<SiteProduct> items) {
    _mergeProducts(items, replace: true);
    notifyListeners();
  }

  void applyProductPage(
    List<SiteProduct> items, {
    required String nextCursor,
    required bool hasMore,
    bool replace = true,
  }) {
    _mergeProducts(items, replace: replace);
    productNextCursor = nextCursor;
    productHasMore = hasMore;
    notifyListeners();
  }

  void setGrants(List<SiteGrant> items) {
    _grants = List<SiteGrant>.from(items);
    notifyListeners();
  }

  void setQueues(List<SiteQueue> items) {
    _queues = List<SiteQueue>.from(items);
    notifyListeners();
  }

  void setWorkShifts(List<SiteWorkShift> items) {
    _workShifts = List<SiteWorkShift>.from(items);
    notifyListeners();
  }

  void upsertQueue(SiteQueue queue) {
    final id = queue.queueId.toInt();
    final idx = _queues.indexWhere((q) => q.queueId.toInt() == id);
    if (idx < 0) {
      _queues = [..._queues, queue];
    } else {
      final next = [..._queues];
      next[idx] = queue;
      _queues = next;
    }
    notifyListeners();
  }
}
