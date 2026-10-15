import 'package:alienai_c35/c/site/design/site_design_models.dart';

const siteHubPostsPreviewLimitDefault = 9;
const siteHubPostsPreviewLimitMax = 20;

/// Normalized hub tab id: `shop` | `posts`.
String siteHubDefaultTabNormalize(String raw) => raw.trim().toLowerCase() == 'posts' ? 'posts' : 'shop';

int siteHubPostsPreviewLimit(SiteProfileDesignDraft design) {
  final n = design.hubPostsPreviewLimit;
  if (n <= 0) return siteHubPostsPreviewLimitDefault;
  return n.clamp(1, siteHubPostsPreviewLimitMax);
}

bool siteHubShowTabs({required bool hasProducts, required bool hasPosts}) => hasProducts && hasPosts;

String siteHubInitialTab({
  required SiteProfileDesignDraft design,
  required bool hasProducts,
  required bool hasPosts,
}) {
  if (!siteHubShowTabs(hasProducts: hasProducts, hasPosts: hasPosts)) {
    if (hasProducts) return 'shop';
    if (hasPosts) return 'posts';
    return 'shop';
  }
  final want = siteHubDefaultTabNormalize(design.hubDefaultTab);
  if (want == 'posts' && hasPosts) return 'posts';
  if (want == 'shop' && hasProducts) return 'shop';
  return hasProducts ? 'shop' : 'posts';
}

List<Map<String, dynamic>> siteHubPostsVisibleMaps(
  List<Map<String, dynamic>> posts, {
  required int limit,
  required bool expanded,
}) {
  if (expanded || posts.length <= limit) return posts;
  return posts.take(limit).toList(growable: false);
}

bool siteHubPostsHasMoreMaps(List<Map<String, dynamic>> posts, int limit) => posts.length > limit;
