import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _danger = Color(0xFFF87171);

/// Long-press / overflow menu: archive, delete (unused only), duplicate.
Future<void> showSiteProductActionMenu({
  required BuildContext context,
  required SiteProduct product,
  required VoidCallback onArchiveToggle,
  VoidCallback? onDelete,
  required VoidCallback onDuplicate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) {
      final name = product.name.isEmpty ? 'Product ${product.productId}' : product.name;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Icon(product.isArchived ? Icons.unarchive_outlined : Icons.inventory_2_outlined),
              title: Text(product.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(ctx);
                onArchiveToggle();
              },
            ),
            if (!product.isUsed && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _danger),
                title: const Text('Delete', style: TextStyle(color: _danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                onDuplicate();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<bool> confirmSiteProductDelete(BuildContext context, SiteProduct product) async {
  final name = product.name.isEmpty ? 'this product' : '"${product.name}"';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('Delete product?', style: TextStyle(color: Color(0xFFF4F4F5))),
      content: Text('Remove $name from the catalog. This cannot be undone.', style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: _danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<bool> confirmSiteProductArchive(BuildContext context, SiteProduct product, {required bool archive}) async {
  final name = product.name.isEmpty ? 'this product' : '"${product.name}"';
  final title = archive ? 'Archive product?' : 'Unarchive product?';
  final body = archive
      ? 'Hide $name from the storefront and POS. You can unarchive later.'
      : 'Show $name on the storefront and POS again.';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text(title, style: const TextStyle(color: Color(0xFFF4F4F5))),
      content: Text(body, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(archive ? 'Archive' : 'Unarchive'),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<SiteProduct?> siteProductToggleArchive(SiteApi api, int siteIid, SiteProduct product) async {
  final next = product.clone()..isArchived = !product.isArchived;
  return api.productPut(siteIid, next);
}

Future<SiteProduct?> siteProductDuplicate({
  required SiteApi api,
  required int siteIid,
  required SiteProduct source,
  required int sortOrder,
  List<SiteProductEmbed> embedsForProduct = const [],
}) async {
  final copyName = source.name.isEmpty ? 'Copy' : '${source.name} (copy)';
  final copy = source.clone()
    ..productId = Int64.ZERO
    ..isArchived = false
    ..sortOrder = sortOrder
    ..name = copyName;
  final embedPayload = embedsForProduct
      .map((e) => api.productEmbedNew(siteIid, Int64.ZERO)..label = e.label)
      .toList(growable: false);
  final saved = await api.productPut(siteIid, copy, embeds: embedPayload.isEmpty ? null : embedPayload);
  saved.isUsed = false;
  return saved;
}

Future<void> runSiteProductDelete({
  required BuildContext context,
  required SiteApi api,
  required int siteIid,
  required SiteProduct product,
  required VoidCallback onDeleted,
  required ValueChanged<bool> onBusy,
}) async {
  if (product.isUsed) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This product was used in sales. Archive it instead.')),
    );
    return;
  }
  if (!await confirmSiteProductDelete(context, product)) return;
  onBusy(true);
  try {
    await api.productDelete(siteIid, product.productId);
    onDeleted();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    }
  } finally {
    onBusy(false);
  }
}