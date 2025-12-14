import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/calculate_report_usecase.dart';
import 'package:finance_app/features/transaction/presentation/providers/transaction_notifier.dart';
import '../../domain/entities/report_entity.dart';

// 1. Provider lưu Tháng/Năm đang chọn (Mặc định là tháng hiện tại)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final calculateReportUseCaseProvider = Provider((ref) => CalculateReportUseCase());

// 2. Provider Report đã được nâng cấp để hỗ trợ Filter
final reportProvider = Provider<ReportEntity>((ref) {
  // Lấy toàn bộ giao dịch
  final transactionState = ref.watch(transactionNotifierProvider);
  // Lấy tháng đang chọn
  final selectedDate = ref.watch(selectedDateProvider);
  
  final calculator = ref.read(calculateReportUseCaseProvider);
  
  // Lọc danh sách theo tháng/năm
  final filteredTransactions = transactionState.transactions.where((t) {
    return t.date.month == selectedDate.month && t.date.year == selectedDate.year;
  }).toList();

  // Tính toán dựa trên danh sách đã lọc
  return calculator(filteredTransactions);
});