import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_product_parse_paste.dart';
import 'package:alienai_c35/c/site/site_product_parse_photo.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _border = Color(0xFF27272A);

/// Pick a menu photo, parse items when possible, and create catalog products.
Future<List<SiteProduct>?> uiSiteProductImportFromImage(
  BuildContext context, {
  required SiteApi api,
  required int siteIid,
  int sortOrderStart = 0,
}) async {
  final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
  if (staged == null || staged.isEmpty) return null;
  final file = staged.first;

  if (!context.mounted) return null;
  _UiSiteProductImportBusy.show(context);

  List<SiteProductPasteRow> rows = [];
  String pic = '';
  try {
    final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
    if (up == null || up.hash.isEmpty) throw 'Upload failed';
    pic = fileStoragePath(up.hash);
    rows = await siteProductParsePhoto(conn: api.conn, hash: up.hash, mime: file.mime, name: file.name);
  } catch (_) {
    rows = [];
  } finally {
    if (context.mounted) _UiSiteProductImportBusy.hide(context);
  }

  if (!context.mounted) return null;

  if (rows.isEmpty) {
    final name = await _askName(context);
    if (name == null || name.trim().isEmpty) return null;
    if (pic.isEmpty) {
      try {
        final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
        if (up == null || up.hash.isEmpty) throw 'Upload failed';
        pic = fileStoragePath(up.hash);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
        }
        return null;
      }
    }
    try {
      final p = SiteProduct(
        siteIid: Int64(siteIid),
        name: name.trim(),
        pic: pic,
        canSell: true,
        sortOrder: sortOrderStart,
      );
      return [await api.productPut(siteIid, p)];
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
      return null;
    }
  }

  final confirmed = await _confirmRows(context, rows);
  if (confirmed == null || confirmed.isEmpty) return null;

  try {
    var sort = sortOrderStart;
    final created = <SiteProduct>[];
    for (final row in confirmed) {
      final p = SiteProduct(siteIid: Int64(siteIid), name: row.name, pic: pic, canSell: true, sortOrder: sort++);
      if (row.description.isNotEmpty) p.desc = row.description;
      if (row.price > 0) p.price = Int64(row.price);
      created.add(await api.productPut(siteIid, p));
    }
    return created;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    }
    return null;
  }
}

Future<List<SiteProductPasteRow>?> _confirmRows(BuildContext context, List<SiteProductPasteRow> rows) => showDialog<List<SiteProductPasteRow>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Import from image', style: TextStyle(color: _text, fontSize: 16)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${rows.length} product(s) found. Review before importing.', style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    final price = siteProductImportPriceHint(row.price);
                    return ListTile(
                      dense: true,
                      title: Text(row.name, style: const TextStyle(color: _text, fontSize: 14)),
                      subtitle: row.description.isEmpty
                          ? null
                          : Text(row.description, style: const TextStyle(color: _muted, fontSize: 12)),
                      trailing: price.isEmpty ? null : Text(price, style: const TextStyle(color: _muted, fontSize: 12)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, rows),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
            child: const Text('Import'),
          ),
        ],
      ),
    );

Future<String?> _askName(BuildContext context) async {
  final ctrl = TextEditingController(text: 'New product');
  final res = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('Product name', style: TextStyle(color: _text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Could not read the menu automatically. Enter a name for a single product using this photo.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(hintText: 'Name', hintStyle: TextStyle(color: _muted)),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return res;
}

class _UiSiteProductImportBusy {
  static void show(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              color: Color(0xFF18181B),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                    SizedBox(height: 12),
                    Text('Reading menu image…', style: TextStyle(color: _text, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  static void hide(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}

String siteProductImportPriceHint(int price) => price <= 0 ? '' : moneyFmtIdr(price);
