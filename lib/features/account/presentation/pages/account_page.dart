import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/features/auth/presentation/pages/auth_page.dart';
import 'package:finance_app/core/utils/formatters.dart';
import 'package:finance_app/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import 'package:finance_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:finance_app/features/wallet/presentation/pages/create_wallet_page.dart';
import 'package:finance_app/features/wallet/presentation/pages/wallet_management_page.dart';
import 'settings_page.dart';
import '../widgets/update_profile_dialog.dart'; // Import dialog

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();
    // Load wallet once when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        ref.read(walletNotifierProvider.notifier).loadWallet(authState.user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    if (authState is! AuthAuthenticated) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    final user = authState.user;
    final firstLetter = (user.displayName ?? user.email)[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  firstLetter,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Dùng Consumer để lắng nghe user thay đổi tên hiển thị
            Consumer(
              builder: (context, watch, child) {
                final currentAuth = watch.watch(authNotifierProvider);
                if (currentAuth is AuthAuthenticated) {
                  return Text(
                    currentAuth.user.displayName ?? 'Người dùng',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                }
                return const Text('Người dùng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 8),
            
            Text(
              user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Wallet Card
            _buildWalletCard(context, ref, user.id),

            const SizedBox(height: 24),

            _buildListTile(
              icon: Icons.person_outline,
              title: 'Chỉnh sửa thông tin',
              onTap: () {
                // Mở dialog chỉnh sửa
                showDialog(
                  context: context,
                  builder: (context) => UpdateProfileDialog(currentUser: user),
                );
              },
            ),
            _buildListTile(
              icon: Icons.settings_outlined,
              title: 'Cài đặt',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Trợ giúp & Phản hồi',
              onTap: () {},
            ),

            const Divider(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                onPressed: () {
                  _showLogoutDialog(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WidgetRef ref, String userId) {
    final walletState = ref.watch(walletNotifierProvider);
    final transactionState = ref.watch(transactionNotifierProvider);
    final wallet = walletState.wallet;

    // Don't show wallet card if no wallet or not active
    if (wallet == null || !wallet.isActive) {
      return const SizedBox.shrink();
    }

    // Calculate current balance
    final totalIncome = transactionState.transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpense = transactionState.transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final currentBalance = wallet.initialBalance + totalIncome - totalExpense;
    final balanceColor = currentBalance >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Text(
                  wallet.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Số dư hiện tại:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatCurrency(currentBalance),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _navigateToWallet(BuildContext context, WidgetRef ref) {
    final walletState = ref.read(walletNotifierProvider);
    final wallet = walletState.wallet;

    if (wallet == null || !wallet.isActive) {
      // No wallet -> Create new
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateWalletPage(isOnboarding: false),
        ),
      );
    } else {
      // Has wallet -> Manage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WalletManagementPage(),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}