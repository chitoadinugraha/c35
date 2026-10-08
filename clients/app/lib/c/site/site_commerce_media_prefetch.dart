import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';

Iterable<String> siteCommerceMediaSrcsFromProduct(SiteProduct product) sync* {
  final pic = product.pic.trim();
  if (pic.isNotEmpty) yield pic;
  for (final extra in siteProductPicsRead(product)) {
    if (extra.trim().isNotEmpty) yield extra.trim();
  }
}

Future<void> siteCommerceMediaPrefetch({
  List<SiteProduct>? products,
  String? sitePic,
}) =>
    mediaDiskCachePrefetch([
      if (sitePic != null && sitePic.trim().isNotEmpty) sitePic.trim(),
      ...?products?.expand(siteCommerceMediaSrcsFromProduct),
    ]);
