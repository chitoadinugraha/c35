import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_business_info.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/ui_pos_receipt_shell.dart';
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
    this.autoPrintThermalOnOpen = false,
    this.doneLabel = 'Selesai',
  });

  final Tx tx;
  final SiteApi siteApi;
  final SiteRow? site;
  final ReceiptConfig? config;
  final Map<String, String>? productNames;
  final bool autoPrintThermalOnOpen;
  final String doneLabel;

  @override
  Widget build(BuildContext context) => FutureBuilder<_ReceiptPreviewData>(
        future: _previewData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: UILoading());
          final data = snapshot.data!;
          return UiPosReceiptShell(
            tx: tx,
            config: data.config,
            productNames: data.productNames,
            alienId: data.alienId,
            site: site,
            autoPrintThermalOnOpen: autoPrintThermalOnOpen,
            doneLabel: doneLabel,
          );
        },
      );

  Future<_ReceiptPreviewData> _previewData() async {
    SiteConfig? siteConfig;
    final namesFuture = productNames != null ? Future.value(productNames!) : _productNames(tx);
    try {
      siteConfig = await siteApi.configGet(tx.siteIid.toInt());
    } catch (_) {}
    final fromSite = receiptConfigOf(site, config: siteConfig);
    final base = config ?? ReceiptConfig(showQrLink: fromSite.showQrLink);
    final cfg = receiptConfigMerge(base, fromSite);
    final logoPath = cfg.projectLogo.trim();
    await ReceiptBusinessInfo.prefetchLogo(logoPath.isNotEmpty ? logoPath : null);
    final names = await namesFuture;
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

Future<void> showNotaPage(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  ReceiptConfig? config,
  Map<String, String>? productNames,
  bool autoPrintThermalOnOpen = false,
  bool fullscreenDialog = false,
  String doneLabel = 'Selesai',
}) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: fullscreenDialog,
        builder: (_) => UIReceipt(
          tx: tx,
          siteApi: siteApi,
          site: site,
          config: config,
          productNames: productNames,
          autoPrintThermalOnOpen: autoPrintThermalOnOpen,
          doneLabel: doneLabel,
        ),
      ),
    );

Future<void> showPrintReceipt(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  ReceiptConfig? config,
  Map<String, String>? productNames,
}) =>
    showNotaPage(
      context,
      tx,
      siteApi: siteApi,
      site: site,
      config: config,
      productNames: productNames,
    );

Future<void> showViewReceipt(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  ReceiptConfig? config,
  Map<String, String>? productNames,
}) =>
    showNotaPage(
      context,
      tx,
      siteApi: siteApi,
      site: site,
      config: config,
      productNames: productNames,
    );

Future<void> showPosReceiptAfterSale(
  BuildContext context,
  Tx tx, {
  required SiteApi siteApi,
  SiteRow? site,
  Map<String, String>? productNames,
  ReceiptConfig? config,
}) =>
    showNotaPage(
      context,
      tx,
      siteApi: siteApi,
      site: site,
      productNames: productNames,
      config: config,
      autoPrintThermalOnOpen: true,
      fullscreenDialog: true,
    );
