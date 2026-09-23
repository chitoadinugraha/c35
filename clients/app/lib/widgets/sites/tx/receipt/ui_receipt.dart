import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_preview.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class UIReceipt extends StatelessWidget {
  const UIReceipt({
    super.key,
    required this.tx,
    required this.siteApi,
    this.site,
    this.config,
    this.productNames,
    this.print = false,
    this.watermark,
  });

  final Tx tx;
  final SiteApi siteApi;
  final SiteRow? site;
  final ReceiptConfig? config;
  final Map<String, String>? productNames;
  final bool print;
  final String? watermark;

  @override
  Widget build(BuildContext context) => FutureBuilder<_ReceiptPreviewData>(
        future: _previewData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: UILoading());
          final data = snapshot.data!;
          return ReceiptPdfPreview(
            tx: tx,
            config: data.config,
            productNames: data.productNames,
            alienId: data.alienId,
            print: print,
            watermark: watermark,
          );
        },
      );

  Future<_ReceiptPreviewData> _previewData() async {
    final base = config ?? const ReceiptConfig();
    SiteConfig? siteConfig;
    try {
      siteConfig = await siteApi.configGet(tx.siteIid.toInt());
    } catch (_) {}
    final fromSite = receiptConfigOf(site, config: siteConfig);
    final cfg = receiptConfigMerge(base, fromSite);
    final names = productNames ?? await _productNames(tx);
    return _ReceiptPreviewData(config: cfg, productNames: names, alienId: site?.alienId);
  }

  Future<Map<String, String>> _productNames(Tx tx) async {
    final names = <String, String>{};
    final ids = tx.items.map((item) => item.productId).where((id) => id > Int64.ZERO).toSet();
    if (ids.isEmpty) return names;
    final products = await siteApi.productList(tx.siteIid.toInt());
    for (final product in products) {
      if (ids.contains(product.productId)) names[product.productId.toString()] = product.name;
    }
    return names;
  }
}

class _ReceiptPreviewData {
  final ReceiptConfig config;
  final Map<String, String> productNames;
  final String? alienId;

  const _ReceiptPreviewData({required this.config, required this.productNames, this.alienId});
}

Future<void> showPrintReceipt(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  ReceiptConfig? config,
  Map<String, String>? productNames,
  String? watermark,
}) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UIReceipt(
          tx: tx,
          siteApi: siteApi,
          site: site,
          config: config,
          productNames: productNames,
          watermark: watermark,
          print: true,
        ),
      ),
    );

Future<void> showViewReceipt(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  ReceiptConfig? config,
  Map<String, String>? productNames,
  String? watermark,
}) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UIReceipt(
          tx: tx,
          siteApi: siteApi,
          site: site,
          config: config,
          productNames: productNames,
          watermark: watermark,
        ),
      ),
    );
