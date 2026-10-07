import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/services.dart';

const moneyIdrInputFormatters = [MoneyIdrInputFormatter()];

/// Indonesian Rupiah amount field: digits only, displayed with `.` grouping (50.000).
class MoneyIdrInputFormatter extends TextInputFormatter {
  const MoneyIdrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final n = int.tryParse(digits) ?? 0;
    final formatted = moneyFmtIdrGrouped(n);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
