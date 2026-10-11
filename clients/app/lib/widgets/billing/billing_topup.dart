import 'package:alienai_c35/c/ui/money_format.dart';

const billingTopupMinIdr = 50000.0;
const billingTopupMinUsd = 10.0;
const billingTopupPacksIdr = [50000.0, 100000.0, 200000.0, 500000.0, 1000000.0];
const billingTopupPacksUsd = [10.0, 20.0, 50.0];

bool billingUsesIdr({double balanceIdr = 0}) => balanceIdr > 0;

double billingUsdToIdr(double usd, {double fxRate = 17630}) => usd * fxRate;

int? billingTopupParseIdr(String raw) => moneyParseIdrInt(raw);

String billingTopupIdrLabel(double idr) => moneyFmtIdr(idr);

String billingTopupUsdLabel(double usd) => moneyFmtUsd(usd, decimals: 0);

bool billingTopupAmountOk({required double amountUsd, double amountIdr = 0, bool usesIdr = false}) =>
    usesIdr ? amountIdr >= billingTopupMinIdr : amountUsd >= billingTopupMinUsd;
