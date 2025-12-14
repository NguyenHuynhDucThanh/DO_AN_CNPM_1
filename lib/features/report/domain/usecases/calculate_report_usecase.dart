import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import '../entities/chart_data_entity.dart';
import '../entities/report_entity.dart';

class CalculateReportUseCase {
  ReportEntity call(List<TransactionEntity> transactions) {
    double income = 0;
    double expense = 0;
    
    // Map để gom nhóm chi tiêu theo category
    final Map<String, double> expenseByCategory = {};

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        // Cộng dồn tiền theo danh mục
        if (expenseByCategory.containsKey(t.category)) {
          expenseByCategory[t.category] = expenseByCategory[t.category]! + t.amount;
        } else {
          expenseByCategory[t.category] = t.amount;
        }
      }
    }

    // Xử lý dữ liệu biểu đồ
    final List<ChartDataEntity> chartData = [];
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];
    int colorIndex = 0;

    expenseByCategory.forEach((category, amount) {
      if (expense > 0) {
        chartData.add(ChartDataEntity(
          categoryName: category,
          amount: amount,
          percentage: (amount / expense) * 100,
          color: colors[colorIndex % colors.length],
        ));
        colorIndex++;
      }
    });

    // Sắp xếp biểu đồ từ lớn đến bé
    chartData.sort((a, b) => b.amount.compareTo(a.amount));

    return ReportEntity(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      expenseChartData: chartData,
    );
  }
}