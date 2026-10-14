import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/io/in_duration.dart';

String productListStockLabel(SiteProduct product, SiteProductExtras extras) {
  final unit = extras.stockUnit.trim();
  final unitSuffix = unit.isEmpty ? '' : ' $unit';
  return 'Stock: ${moneyFmtIdrGrouped(product.stockQty.toInt())}$unitSuffix';
}

String productListDurationLabel(SiteProductExtras extras) {
  final n = extras.durationValue > 0 ? extras.durationValue : 1;
  final unit = inDurationPeriodOf(extras.durationUnit).label;
  return 'Per: ${moneyFmtIdrGrouped(n)} $unit';
}
