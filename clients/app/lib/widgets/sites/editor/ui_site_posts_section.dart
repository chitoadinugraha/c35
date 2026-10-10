import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSitePostsSection extends StatelessWidget {
  const UiSitePostsSection({
    super.key,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.posts,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.addBusy,
    required this.onStorefrontChanged,
  });

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<SitePost> posts;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final bool addBusy;
  final void Function(String id, bool onStorefront) onStorefrontChanged;

  List<SitePost> get _filtered {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return posts;
    return posts
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.caption.toLowerCase().contains(q) ||
            p.body.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: searchController,
          hintText: 'Search posts',
          onSearchChanged: onSearchChanged,
          onAdd: onAdd,
          addBusy: addBusy,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'No posts yet',
                  subtitle: 'Add a post to show on your hub',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final post = filtered[i];
                    final id = '${post.postId}';
                    return _UiSitePostListTile(
                      post: post,
                      selected: selectedId == id,
                      onTap: () => onSelect(id),
                      onStorefrontChanged: (v) => onStorefrontChanged(id, v),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UiSitePostListTile extends StatelessWidget {
  const _UiSitePostListTile({
    required this.post,
    required this.selected,
    required this.onTap,
    required this.onStorefrontChanged,
  });

  final SitePost post;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onStorefrontChanged;

  @override
  Widget build(BuildContext context) {
    final title = post.title.trim().isEmpty ? 'Untitled' : post.title.trim();
    final caption = post.caption.trim();
    final thumb = post.thumb.trim();
    return Material(
      color: selected ? const Color(0xFF1A1F2E) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 6, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: selected ? _accent : Colors.transparent, width: 3),
              bottom: BorderSide(color: _border.withValues(alpha: 0.55)),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: thumb.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFF18181B),
                            child: Icon(Icons.image_outlined, size: 22, color: _muted),
                          )
                        : UiImg(
                            src: thumb,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            fallback: const Icon(Icons.image_outlined, size: 22, color: _muted),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: post.onStorefront,
                onChanged: onStorefrontChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
