import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}