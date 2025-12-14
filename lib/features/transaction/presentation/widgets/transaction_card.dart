import 'package:flutter/material.dart';
import 'package:finance_app/core/utils/formatters.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    // Logic hiển thị Subtitle: Danh mục - Ngày tháng
    final subtitleText = "${transaction.category} • ${AppFormatters.formatDate(transaction.date)}";

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            // HIỂN THỊ TÊN GIAO DỊCH (Nếu rỗng thì hiện category)
            title: Text(
              transaction.title.isNotEmpty ? transaction.title : transaction.category,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // HIỂN THỊ DANH MỤC Ở DƯỚI
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitleText),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Text(
                    transaction.note!,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Text(
              AppFormatters.formatCurrency(transaction.amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}