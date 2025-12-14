import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/utils/formatters.dart';
import '../providers/admin_notifier.dart';
import '../widgets/transaction_detail_dialog.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final UserEntity user;

  const UserDetailPage({super.key, required this.user});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load transactions của user này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionManagementNotifierProvider.notifier).loadUserTransactions(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionManagementNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        actions: [
          // Nút khóa/mở khóa
          IconButton(
            icon: Icon(widget.user.isLocked ? Icons.lock_open : Icons.lock),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.user.isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?'),
                  content: Text(
                    widget.user.isLocked
                        ? 'Người dùng sẽ có thể đăng nhập lại.'
                        : 'Người dùng sẽ không thể đăng nhập.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await ref
                    .read(userManagementNotifierProvider.notifier)
                    .toggleLockUser(widget.user.id, !widget.user.isLocked);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.user.isLocked ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
          // Nút xóa
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa người dùng?'),
                  content: const Text(
                    'Hành động này sẽ xóa người dùng và TẤT CẢ giao dịch của họ. Không thể hoàn tác!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await ref
                    .read(userManagementNotifierProvider.notifier)
                    .deleteUser(widget.user.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa người dùng')),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: widget.user.isAdmin ? Colors.red : Colors.blue,
                          child: Icon(
                            widget.user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.displayName ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.user.email,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('User ID', widget.user.id),
                    _buildInfoRow('Role', widget.user.role.toUpperCase()),
                    _buildInfoRow(
                      'Status',
                      widget.user.isLocked ? 'LOCKED' : 'ACTIVE',
                      valueColor: widget.user.isLocked ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Transactions Section
            Text(
              'Giao dịch (${transactionState.transactions.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (transactionState.isLoading)
              const Center(child: LoadingWidget())
            else if (transactionState.transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Người dùng chưa có giao dịch nào'),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactionState.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactionState.transactions[index];
                  final isIncome = transaction.type == TransactionType.income;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green : Colors.red,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(transaction.title),
                      subtitle: Text(
                        '${transaction.category} • ${_formatDate(transaction.date)}',
                      ),
                      trailing: Text(
                        AppFormatters.formatCurrency(transaction.amount),
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        _showTransactionDetail(context, transaction);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show transaction detail dialog
  void _showTransactionDetail(BuildContext context, TransactionEntity transaction) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailDialog(transaction: transaction),
    );
  }
}
