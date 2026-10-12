import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_mode.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/ui_pos_queue_panel.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF08080A);
const _text = Color(0xFFF4F4F5);

class PagePosQueueDesk extends StatelessWidget {
  const PagePosQueueDesk({
    super.key,
    required this.mode,
    required this.txApi,
    required this.siteIid,
    this.products = const [],
  });

  final PosQueueMode mode;
  final TxApi txApi;
  final int siteIid;
  final List<SiteProduct> products;

  String get _title => switch (mode) {
        PosQueueMode.paymentVerification => 'Payment verification',
        PosQueueMode.orders => 'Kitchen orders',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: Text(_title),
      ),
      body: SafeArea(
        child: UiPosQueuePanel(
          mode: mode,
          txApi: txApi,
          siteIid: siteIid,
          products: products,
          expanded: true,
        ),
      ),
    );
  }
}
