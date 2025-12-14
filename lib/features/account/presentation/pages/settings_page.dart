import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:finance_app/features/wallet/presentation/pages/create_wallet_page.dart';
import 'package:finance_app/features/wallet/presentation/pages/wallet_management_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          
          // Wallet
          _buildListTile(
            context: context,
            icon: Icons.account_balance_wallet,
            title: 'Ví',
            subtitle: 'Quản lý ví của bạn',
            onTap: () => _navigateToWallet(context, ref),
          ),

          const Divider(),

          // Ngôn ngữ
          _buildListTile(
            context: context,
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          // Thông báo
          _buildListTile(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: 'Cài đặt thông báo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          // Bảo mật
          _buildListTile(
            context: context,
            icon: Icons.security,
            title: 'Bảo mật',
            subtitle: 'Đổi mật khẩu, xác thực 2 lớp',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const Divider(),

          // Về ứng dụng
          _buildListTile(
            context: context,
            icon: Icons.info_outline,
            title: 'Về ứng dụng',
            subtitle: 'Phiên bản 1.0.0',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
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
}
