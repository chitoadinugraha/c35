import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_mode.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/ui_pos_queue_panel.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);

Future<void> showPosQueueSheet({
  required BuildContext context,
  required PosQueueMode mode,
  required TxApi txApi,
  required int siteIid,
  List<SiteProduct> products = const [],
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121215),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: _border),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (_, scrollController) => PrimaryScrollController(
        controller: scrollController,
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.92,
          child: UiPosQueuePanel(
            mode: mode,
            txApi: txApi,
            siteIid: siteIid,
            products: products,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    ),
  );
}
