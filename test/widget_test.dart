import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/features/report/domain/usecases/calculate_report_usecase.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  test('CalculateReportUseCase summarizes income and expenses', () {
    final calculator = CalculateReportUseCase();
    final transactions = [
      TransactionEntity(
        id: 'expense-1',
        userId: 'user-1',
        amount: 100000,
        type: TransactionType.expense,
        category: 'Food',
        title: 'Lunch',
        date: DateTime(2026, 4, 11),
      ),
      TransactionEntity(
        id: 'income-1',
        userId: 'user-1',
        amount: 300000,
        type: TransactionType.income,
        category: 'Salary',
        title: 'Salary',
        date: DateTime(2026, 4, 14),
      ),
    ];

    final report = calculator(transactions);

    expect(report.totalExpense, 100000);
    expect(report.totalIncome, 300000);
    expect(report.balance, 200000);
    expect(report.expenseChartData.single.categoryName, 'Food');
    expect(report.expenseChartData.single.percentage, 100);
  });
}
