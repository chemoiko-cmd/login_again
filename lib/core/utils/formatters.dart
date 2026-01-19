String formatDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String formatNumberWithCommas(double value) {
  final isNegative = value < 0;
  final absVal = value.abs();
  final decimals = (absVal % 1 == 0) ? 0 : 2;
  String s = absVal.toStringAsFixed(decimals);
  final parts = s.split('.');
  String intPart = parts[0];
  final fracPart = parts.length > 1 ? parts[1] : null;
  final reg = RegExp(r"(\d+)(\d{3})");
  while (reg.hasMatch(intPart)) {
    intPart = intPart.replaceAllMapped(reg, (m) => "${m[1]},${m[2]}");
  }
  String out = (fracPart == null || fracPart.isEmpty)
      ? intPart
      : "$intPart.$fracPart";
  if (isNegative) out = "-$out";
  return out;
}

String formatMoney(double? amount, {String? currencySymbol}) {
  if (amount == null) return '—';
  final sym = (currencySymbol ?? '').trim();
  final numStr = formatNumberWithCommas(amount);
  return sym.isEmpty ? numStr : '$sym $numStr';
}

String formatCurrency(
  double? amount, {
  String? currencySymbol,
  String position = 'before',
}) {
  if (amount == null) return '—';
  final numStr = formatNumberWithCommas(amount);
  final sym = (currencySymbol ?? '').trim();
  if (sym.isEmpty) return numStr;
  return position == 'after' ? '$numStr $sym' : '$sym $numStr';
}

String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
