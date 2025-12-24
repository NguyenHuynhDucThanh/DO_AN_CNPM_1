import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/widgets/error_widget.dart';
import '../../../transaction/presentation/providers/transaction_notifier.dart';
import '../../../transaction/presentation/pages/add_transaction_page.dart';
import '../../../transaction/presentation/widgets/transaction_card.dart';
import '../providers/home_providers.dart';
import 'month_selector.dart';
import 'empty_transaction_state.dart';

/// Tab hiển thị danh sách giao dịch với filtering theo tháng/năm
class TransactionTab extends ConsumerWidget {
  final UserEntity user;
  final VoidCallback onReloadData;

  const TransactionTab({
    super.key,
    required this.user,
    required this.onReloadData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionNotifierProvider);
    final selectedDate = ref.watch(transactionSelectedDateProvider);

    // Loading state
    if (transactionState.isLoading && transactionState.transactions.isEmpty) {
      return const LoadingWidget();
    }

    // Error state
    if (transactionState.errorMessage != null) {
      return AppErrorWidget(
        message: transactionState.errorMessage!,
        onRetry: onReloadData,
      );
    }

    // Filter transactions theo tháng/năm được chọn
    final filteredTransactions = transactionState.transactions.where((tx) {
      return tx.date.year == selectedDate.year &&
          tx.date.month == selectedDate.month;
    }).toList();

    return Column(
      children: [
        // Month Selector
        MonthSelector(currentDate: selectedDate),
        const Divider(height: 1),

        // Transaction List hoặc Empty State
        Expanded(
          child: filteredTransactions.isEmpty
              ? EmptyTransactionState(date: selectedDate)
              : _buildTransactionList(context, ref, filteredTransactions),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List transactions,
  ) {
    return RefreshIndicator(
      onRefresh: () async => onReloadData(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];

          try {
            return TransactionCard(
              transaction: transaction,
              
              // Delete callback
              onDelete: () {
                ref
                    .read(transactionNotifierProvider.notifier)
                    .deleteTransaction(transaction.id, user.id);
              },
              
              // Edit callback
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionFormPage(
                      userId: user.id,
                      transactionToEdit: transaction,
                    ),
                  ),
                );

                // Reload nếu đã save thành công
                if (result == true) {
                  onReloadData();
                }
              },
            );
          } catch (e) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Text('Lỗi hiển thị'),
            );
          }
        },
      ),
    );
  }
}
