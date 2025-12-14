import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/widgets/error_widget.dart';
import '../providers/admin_notifier.dart';
import 'user_detail_page.dart';

class UsersManagementPage extends ConsumerStatefulWidget {
  const UsersManagementPage({super.key});

  @override
  ConsumerState<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<UsersManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementNotifierProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementNotifierProvider);

    if (state.isLoading && state.users.isEmpty) {
      return const LoadingWidget();
    }

    if (state.errorMessage != null && state.users.isEmpty) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () => ref.read(userManagementNotifierProvider.notifier).loadUsers(),
      );
    }

    // Filter: Chỉ hiển thị user thường, ẩn tất cả admin
    final regularUsers = state.users.where((user) => user.role != 'admin').toList();

    if (regularUsers.isEmpty) {
      return const Center(
        child: Text('Không có người dùng nào'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(userManagementNotifierProvider.notifier).loadUsers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: regularUsers.length,
        itemBuilder: (context, index) {
          final user = regularUsers[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.isAdmin ? Colors.red : Colors.blue,
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                user.displayName ?? user.email,
                style: TextStyle(
                  decoration: user.isLocked ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: user.isAdmin ? Colors.red[100] : Colors.blue[100],
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (user.isLocked) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('LOCKED', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserDetailPage(user: user),
                  ),
                );
                // Reload sau khi quay lại
                ref.read(userManagementNotifierProvider.notifier).loadUsers();
              },
            ),
          );
        },
      ),
    );
  }
}
