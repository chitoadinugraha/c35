import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/billing/billing_topup.dart';

const billingManualBank = 'BCA';
const billingManualAccount = '0113543750';
const billingManualAccountName = 'PT Percepatan Akhir Semesta';

String billingManualTransferInstructions({required double amountIdr}) =>
    billingManualTransferInstructionsFromAccount(
      amountIdr: amountIdr,
      bankId: billingManualBank,
      accountNumber: billingManualAccount,
      accountName: billingManualAccountName,
    );

String billingManualTransferInstructionsFromAccount({
  required double amountIdr,
  required String bankId,
  required String accountNumber,
  required String accountName,
}) =>
    'Transfer ${billingTopupIdrLabel(amountIdr)} ke $bankId $accountNumber a.n. $accountName, lalu upload bukti transfer.';
