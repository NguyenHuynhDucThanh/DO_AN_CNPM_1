import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/utils/formatters.dart';
import 'package:finance_app/core/widgets/month_year_picker_dialog.dart';
import '../providers/report_providers.dart';
import '../widgets/expense_pie_chart.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe dữ liệu report (đã được lọc theo tháng)
    final report = ref.watch(reportProvider);
    // Lắng nghe tháng đang được chọn
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THANH CHỌN THÁNG (Mới thêm)
            _buildMonthSelector(context, ref, selectedDate),
            
            const SizedBox(height: 16),

            // 2. Thẻ tổng quan
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Thu nhập', report.totalIncome, Colors.green),
                        _buildSummaryItem('Chi tiêu', report.totalExpense, Colors.red),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Số dư: ', style: TextStyle(fontSize: 18)),
                        Text(
                          AppFormatters.formatCurrency(report.balance),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: report.balance >= 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Biểu đồ (Có kiểm tra dữ liệu rỗng)
            if (report.totalExpense == 0 && report.totalIncome == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.insert_chart_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Không có dữ liệu trong tháng này',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const Text(
                'Phân bổ chi tiêu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ExpensePieChart(data: report.expenseChartData),
            ]
          ],
        ),
      ),
    );
  }

  // Widget chọn tháng/năm: Click để mở picker
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime currentDate) {
    return Center(
      child: InkWell(
        onTap: () async {
          await _showMonthYearPicker(context, ref, currentDate);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.blue.shade50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Tháng ${currentDate.month}/${currentDate.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  // Show month/year picker dialog
  Future<void> _showMonthYearPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthYearPickerDialog(initialDate: currentDate),
    );

    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );

  }
}