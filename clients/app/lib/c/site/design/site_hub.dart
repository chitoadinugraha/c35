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
