import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/widgets/error_widget.dart';

// Import các Feature
import '../../../transaction/presentation/providers/transaction_notifier.dart';
import '../../../transaction/presentation/pages/add_transaction_page.dart'; // Class bên trong này là TransactionFormPage
import '../../../transaction/presentation/widgets/transaction_card.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
// Import Search Delegate
import '../../../transaction/presentation/delegates/transaction_search_delegate.dart';

// Provider để lưu tháng/năm được chọn cho transaction list
final transactionSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

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
      _buildTransactionTab(user), // Tab 0
      const ReportPage(),         // Tab 1
      const AccountPage(),        // Tab 2
    ];

    return Scaffold(
      // AppBar chỉ hiện ở Tab 0 (Giao dịch)
      appBar: _currentIndex == 0
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sổ Thu Chi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user.displayName ?? user.email,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
              // --- THÊM PHẦN NÀY: Nút Tìm kiếm ---
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Lấy danh sách hiện tại từ Riverpod
                    final currentState = ref.read(transactionNotifierProvider);
                    
                    showSearch(
                      context: context,
                      delegate: TransactionSearchDelegate(
                        transactions: currentState.transactions, // Truyền list qua
                        ref: ref,
                        userId: user.id,
                        onReload: _loadData, // Truyền hàm reload để dùng khi sửa xong
                      ),
                    );
                  },
                ),
              ],
              // -----------------------------------
            )
          : null,

      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      // Nút Thêm mới
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                // Check if user has active wallet before allowing transaction creation
                final walletState = ref.read(walletNotifierProvider);
                final wallet = walletState.wallet;
                
                if (wallet == null || !wallet.isActive) {
                  // No wallet - show dialog
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
                            Navigator.pop(context); // Close dialog
                            // Navigate to Account tab (index 2)
                            setState(() => _currentIndex = 2);
                          },
                          child: const Text('Đi tới Tài khoản'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                // Has wallet - allow transaction creation
                // Hứng kết quả trả về từ trang Form
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => TransactionFormPage(userId: user.id)),
                );
                
                // CHỈ LOAD LẠI KHI CÓ KẾT QUẢ TRUE (Tức là đã bấm Lưu thành công)
                if (result == true) {
                  _loadData();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,

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

  Widget _buildTransactionTab(dynamic user) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(transactionNotifierProvider);
        final selectedDate = ref.watch(transactionSelectedDateProvider);

        if (transactionState.isLoading && transactionState.transactions.isEmpty) {
          return const LoadingWidget();
        }

        if (transactionState.errorMessage != null) {
          return AppErrorWidget(
            message: transactionState.errorMessage!,
            onRetry: _loadData,
          );
        }

        // Filter transactions theo tháng/năm được chọn
        final filteredTransactions = transactionState.transactions.where((tx) {
          return tx.date.year == selectedDate.year && tx.date.month == selectedDate.month;
        }).toList();

        return Column(
          children: [
            // Month/Year Picker
            _buildMonthSelector(context, ref, selectedDate),
            const Divider(height: 1),
            
            // Transaction List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Không có giao dịch trong tháng ${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadData(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          try {
                            return TransactionCard(
                              transaction: transaction,
                              onDelete: () {
                                ref
                                    .read(transactionNotifierProvider.notifier)
                                    .deleteTransaction(transaction.id, user.id);
                              },
                              // Chỉnh sửa giao dịch
                              onTap: () async {
                                // Hứng kết quả trả về
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionFormPage(
                                      userId: user.id,
                                      transactionToEdit: transaction, // Truyền dữ liệu cũ vào để sửa
                                    ),
                                  ),
                                );
                                
                                // CHỈ LOAD LẠI KHI CÓ KẾT QUẢ TRUE (Nếu bấm Back thì result là null -> Không load lại)
                                if (result == true) {
                                  _loadData();
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
                    ),
            ),
          ],
        );
      },
    );
  }

  // Month Picker Button
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime currentDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: InkWell(
          onTap: () async {
            final picked = await showDialog<DateTime>(
              context: context,
              builder: (context) => _MonthYearPickerDialog(initialDate: currentDate),
            );

            if (picked != null) {
              ref.read(transactionSelectedDateProvider.notifier).state = picked;
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: Colors.blue.shade50,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Tháng ${currentDate.month}/${currentDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reuse MonthYearPickerDialog từ report page
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthYearPickerDialog({required this.initialDate});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 5 + index);

    return AlertDialog(
      title: const Text('Chọn tháng và năm'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          children: [
            // Year Selector
            const Text('Năm', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: selectedYear,
              isExpanded: true,
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedYear = value!);
              },
            ),
            const SizedBox(height: 24),
            
            // Month Grid
            const Text('Tháng', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == selectedMonth;
                  
                  return Material(
                    color: isSelected ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() => selectedMonth = month);
                      },
                      child: Center(
                        child: Text(
                          _getMonthName(month),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, DateTime(selectedYear, selectedMonth));
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12',
    ];
    return monthNames[month - 1];
  }
}