/// "Rs. 12,490" — matches `formatPrice` (en-PK grouping) on the web store.
String formatPrice(num amount) => 'Rs. ${groupDigits(amount.round())}';

String groupDigits(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buf';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "12 Oct 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "12 Oct"
String formatShortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "12 Oct, 4:05 pm"
String formatDateTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '${formatShortDate(d)}, $hour:$minute ${d.hour < 12 ? 'am' : 'pm'}';
}

String pluralize(int n, String singular, [String? plural]) =>
    '$n ${n == 1 ? singular : (plural ?? '${singular}s')}';
