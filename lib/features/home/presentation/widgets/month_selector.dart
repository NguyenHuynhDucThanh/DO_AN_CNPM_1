import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/widgets/month_year_picker_dialog.dart';
import '../providers/home_providers.dart';

/// Widget button để chọn tháng/năm
/// Khi click sẽ mở MonthYearPickerDialog
class MonthSelector extends ConsumerWidget {
  final DateTime currentDate;

  const MonthSelector({
    super.key,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: InkWell(
          onTap: () => _showMonthPicker(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: Colors.blue.shade50,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Tháng ${currentDate.month}/${currentDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthYearPickerDialog(initialDate: currentDate),
    );

    if (picked != null) {
      ref.read(transactionSelectedDateProvider.notifier).state = picked;
    }
  }
}
