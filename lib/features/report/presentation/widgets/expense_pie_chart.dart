import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/chart_data_entity.dart';
import 'package:finance_app/core/utils/formatters.dart';

class ExpensePieChart extends StatelessWidget {
  final List<ChartDataEntity> data;

  const ExpensePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu chi tiêu')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((item) {
                return PieChartSectionData(
                  color: item.color,
                  value: item.amount,
                  title: '${item.percentage.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Chú thích (Legend)
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: data.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: item.color),
                const SizedBox(width: 4),
                Text('${item.categoryName} (${AppFormatters.formatCurrency(item.amount)})'),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}