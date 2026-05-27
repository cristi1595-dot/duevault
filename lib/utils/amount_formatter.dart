extension AmountFormatting on double {
  String formatAmount() {
    if (this % 1 == 0) {
      return toInt().toString();
    } else {
      return toStringAsFixed(2);
    }
  }
}
