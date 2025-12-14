import 'package:flutter/material.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:finance_app/core/utils/formatters.dart';

/// Dialog hiển thị chi tiết đầy đủ của một transaction
/// Dùng cho admin khi xem transactions của user
class TransactionDetailDialog extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          const Text('Chi tiết giao dịch'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Transaction ID', transaction.id),
            _buildDetailRow('Tiêu đề', transaction.title),
            _buildDetailRow('Loại', isIncome ? 'Thu nhập' : 'Chi tiêu'),
            _buildDetailRow('Danh mục', transaction.category),
            _buildDetailRow(
              'Số tiền',
              AppFormatters.formatCurrency(transaction.amount),
              valueColor: isIncome ? Colors.green : Colors.red,
            ),
            _buildDetailRow('Ngày', _formatDate(transaction.date)),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              _buildDetailRow('Ghi chú', transaction.note!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
