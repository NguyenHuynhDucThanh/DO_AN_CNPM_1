import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/utils/currency_input_formatter.dart';
import 'package:finance_app/core/utils/formatters.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/features/transaction/presentation/providers/transaction_notifier.dart';
import '../providers/wallet_notifier.dart';
import '../providers/wallet_providers.dart';

class WalletManagementPage extends ConsumerStatefulWidget {
  const WalletManagementPage({super.key});

  @override
  ConsumerState<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends ConsumerState<WalletManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        ref.read(walletNotifierProvider.notifier).loadWallet(authState.user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập')));
    }

    final wallet = walletState.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Ví'),
      ),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wallet == null || !wallet.isActive
              ? _buildNoWallet()
              : _buildWalletInfo(wallet, authState.user.id),
    );
  }

  Widget _buildNoWallet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Bạn chưa có ví', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(wallet, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 60, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    wallet.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Số dư ban đầu', style: TextStyle(color: Colors.grey)),
                  Text(
                    AppFormatters.formatCurrency(wallet.initialBalance),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () => _showEditDialog(wallet, userId),
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => _showDeleteDialog(userId),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Xóa ví', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(wallet, String userId) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(
      text: wallet.initialBalance.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa ví'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ví',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: 'Số dư ban đầu',
                suffixText: 'đ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balanceText = balanceController.text.replaceAll('.', '');
              final balance = double.tryParse(balanceText) ?? 0;

              ref.read(walletNotifierProvider.notifier).updateWallet(userId, name, balance);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ví?'),
        content: const Text(
          'CẢNH BÁO: Xóa ví sẽ XÓA VĨNH VIỄN tất cả giao dịch!\n\n'
          'Bạn sẽ phải tạo ví mới và nhập lại toàn bộ giao dịch từ đầu.\n\n'
          'Bạn có chắc chắn muốn tiếp tục?',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete wallet (also deletes all transactions)
              await ref.read(walletNotifierProvider.notifier).deleteWallet(userId);
              
              // Clear transaction state in app
              ref.read(transactionNotifierProvider.notifier).clearTransactions();
              
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to account page
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA VĨNH VIỄN'),
          ),
        ],
      ),
    );
  }
}
