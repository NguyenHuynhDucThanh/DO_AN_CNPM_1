import 'package:flutter/material.dart';

/// Widget hiển thị empty state khi không có giao dịch trong tháng được chọn
class EmptyTransactionState extends StatelessWidget {
  final DateTime date;

  const EmptyTransactionState({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch trong tháng ${date.month}/${date.year}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
