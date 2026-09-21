import 'package:alienai_c35/c/ui/money_format.dart';

const billingTopupMinIdr = 50000.0;
const billingTopupMinUsd = 10.0;
const billingTopupPacksIdr = [50000.0, 100000.0, 200000.0];
const billingTopupPacksUsd = [10.0, 20.0, 50.0];

const billingManualBank = 'BCA';
const billingManualAccount = '0113543750';
const billingManualAccountName = 'PT Percepatan Akhir Semesta';

bool billingUsesIdr({double balanceIdr = 0}) => balanceIdr > 0;

double billingUsdToIdr(double usd, {double fxRate = 17630}) => usd * fxRate;

int? billingTopupParseIdr(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

String billingTopupIdrLabel(double idr) => moneyFmtIdr(idr);

String billingTopupUsdLabel(double usd) => moneyFmtUsd(usd, decimals: 0);

bool billingTopupAmountOk({required double amountUsd, double amountIdr = 0, bool usesIdr = false}) =>
    usesIdr ? amountIdr >= billingTopupMinIdr : amountUsd >= billingTopupMinUsd;

String billingManualTransferInstructions({required double amountIdr}) =>
    'Transfer ${billingTopupIdrLabel(amountIdr)} ke $billingManualBank $billingManualAccount a.n. $billingManualAccountName, lalu paste link bukti transfer.';
