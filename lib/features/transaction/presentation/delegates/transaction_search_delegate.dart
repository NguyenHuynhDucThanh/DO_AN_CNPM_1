import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_notifier.dart';
import '../widgets/transaction_card.dart';
import '../pages/add_transaction_page.dart'; // TransactionFormPage

class TransactionSearchDelegate extends SearchDelegate {
  final List<TransactionEntity> transactions;
  final WidgetRef ref;
  final String userId;
  final Function onReload; // Callback để load lại data khi cần

  TransactionSearchDelegate({
    required this.transactions,
    required this.ref,
    required this.userId,
    required this.onReload,
  });

  // 1. Nút bên phải thanh tìm kiếm (Thường là nút Xóa text)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = ''; // Xóa nội dung tìm kiếm
          },
        ),
    ];
  }

  // 2. Nút bên trái (Nút Back)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Đóng tìm kiếm
      },
    );
  }

  // 3. Hiển thị kết quả (Khi bấm Enter) - Ở đây ta cho hiện luôn khi gõ
  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  // 4. Hiển thị gợi ý (Khi đang gõ)
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  // Hàm logic lọc và hiển thị danh sách
  Widget _buildList(BuildContext context) {
    // 1. Chuẩn hóa từ khóa tìm kiếm (chữ thường, bỏ khoảng trắng thừa)
    final cleanQuery = query.toLowerCase().trim();

    // 2. Lọc danh sách
    final filteredList = transactions.where((t) {
      final title = t.title.toLowerCase();
      final category = t.category.toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      final amount = t.amount.toString();

      return title.contains(cleanQuery) ||
             category.contains(cleanQuery) ||
             note.contains(cleanQuery) ||
             amount.contains(cleanQuery);
    }).toList();

    // 3. Hiển thị UI
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Không tìm thấy giao dịch nào cho "$query"', 
              style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final transaction = filteredList[index];
        return TransactionCard(
          transaction: transaction,
          onDelete: () {
            // Xóa trực tiếp trong màn hình tìm kiếm
            ref.read(transactionNotifierProvider.notifier).deleteTransaction(transaction.id, userId);
            
            // Hack: Gọi query = query để trigger build lại màn hình sau khi xóa
            // Tuy nhiên, tốt nhất là đóng search hoặc hiện snackbar
            close(context, null);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa giao dịch')),
            );
          },
          onTap: () async {
            // Cho phép sửa ngay trong màn hình tìm kiếm
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionFormPage(
                  userId: userId,
                  transactionToEdit: transaction,
                ),
              ),
            );
            
            if (result == true) {
              onReload(); // Load lại data gốc
              close(context, null); // Đóng search để quay về list mới nhất
            }
          },
        );
      },
    );
  }
  
  @override
  String get searchFieldLabel => 'Tìm kiếm giao dịch...';
}
