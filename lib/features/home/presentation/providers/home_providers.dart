import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider lưu tháng/năm được chọn để filter transactions
final transactionSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
