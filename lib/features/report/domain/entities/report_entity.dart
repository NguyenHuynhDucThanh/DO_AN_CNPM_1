import 'package:equatable/equatable.dart';
import 'chart_data_entity.dart';

class ReportEntity extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<ChartDataEntity> expenseChartData; // Dữ liệu cho biểu đồ chi tiêu

  const ReportEntity({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseChartData,
  });

  @override
  List<Object?> get props => [totalIncome, totalExpense, balance, expenseChartData];
}