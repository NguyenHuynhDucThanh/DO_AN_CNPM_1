import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';

// Import các Feature Pages
import '../../../transaction/presentation/pages/add_transaction_page.dart';
import '../../../transaction/presentation/providers/transaction_notifier.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

// Import Search Delegate
import '../../../transaction/presentation/delegates/transaction_search_delegate.dart';

// Import Home widgets
import '../widgets/transaction_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0; // 0: Giao dịch, 1: Báo cáo, 2: Tài khoản

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      ref.read(transactionNotifierProvider.notifier).fetchTransactions(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: LoadingWidget());
    }

    final user = authState.user;

    // Danh sách các màn hình
    final List<Widget> pages = [
      TransactionTab(user: user, onReloadData: _loadData), // Tab 0
      const ReportPage(),                                   // Tab 1
      const AccountPage(),                                  // Tab 2
    ];

    return Scaffold(
      // AppBar chỉ hiện ở Tab 0 (Giao dịch)
      appBar: _currentIndex == 0 ? _buildAppBar(context, user) : null,

      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      // Nút Thêm mới - chỉ hiện ở Tab 0
      floatingActionButton: _currentIndex == 0 ? _buildFAB(context, user) : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic user) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sổ Thu Chi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(user.displayName ?? user.email,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context, user),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context, dynamic user) {
    final currentState = ref.read(transactionNotifierProvider);

    showSearch(
      context: context,
      delegate: TransactionSearchDelegate(
        transactions: currentState.transactions,
        ref: ref,
        userId: user.id,
        onReload: _loadData,
      ),
    );
  }

  Widget _buildFAB(BuildContext context, dynamic user) {
    return FloatingActionButton(
      onPressed: () => _handleAddTransaction(context, user),
      child: const Icon(Icons.add),
    );
  }

  Future<void> _handleAddTransaction(BuildContext context, dynamic user) async {
    // Check if user has active wallet
    final walletState = ref.read(walletNotifierProvider);
    final wallet = walletState.wallet;

    if (wallet == null || !wallet.isActive) {
      // No wallet - show dialog
      _showNoWalletDialog(context);
      return;
    }

    // Has wallet - allow transaction creation
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(userId: user.id),
      ),
    );

    // Reload nếu đã save thành công
    if (result == true) {
      _loadData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu giao dịch thành công')),
        );
      }
    }
  }

  void _showNoWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần tạo ví'),
        content: const Text(
          'Bạn cần tạo ví trước khi thêm giao dịch.\n\n'
          'Vui lòng vào Tài khoản → Cài đặt → Ví để tạo ví mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2); // Navigate to Account tab
            },
            child: const Text('Đi tới Tài khoản'),
          ),
        ],
      ),
    );
  }
}