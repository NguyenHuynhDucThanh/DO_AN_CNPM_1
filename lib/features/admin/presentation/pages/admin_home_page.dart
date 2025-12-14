import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/features/auth/presentation/pages/auth_page.dart';
import 'users_management_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _currentIndex = 0; // 0: Users, 1: Settings

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    if (authState is! AuthAuthenticated) {
      return const AuthPage();
    }

    final user = authState.user;

    // Danh sách các màn hình
    final List<Widget> pages = [
      const UsersManagementPage(),        // Tab 0
      _buildSettingsTab(user),            // Tab 1
    ];

    final List<String> titles = [
      'Quản lý người dùng',
      'Cài đặt',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titles[_currentIndex]),
            Text(
              'Admin: ${user.displayName ?? user.email}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(dynamic user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Admin Panel',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
