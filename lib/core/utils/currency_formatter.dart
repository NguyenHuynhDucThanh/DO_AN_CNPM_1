import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Formatter cho số tiền VND
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');
  
  /// Format số tiền thành string với dấu chấm phân cách
  /// Ví dụ: 1000000 -> "1.000.000"
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }
  
  /// Format và thêm " đ" vào cuối
  /// Ví dụ: 1000000 -> "1.000.000 đ"
  static String formatWithUnit(double amount) {
    return '${format(amount)} đ';
  }
  
  /// Parse string thành double (bỏ dấu chấm)
  /// Ví dụ: "1.000.000" -> 1000000.0
  static double parse(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
