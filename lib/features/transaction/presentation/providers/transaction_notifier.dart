import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
// Import UseCase Update mới
import '../../domain/usecases/update_transaction_usecase.dart';
import 'transaction_providers.dart';

// 1. Định nghĩa State
class TransactionState extends Equatable {
  final bool isLoading;
  final List<TransactionEntity> transactions;
  final String? errorMessage;
  final bool isSuccess; // Dùng để báo hiệu thêm/xóa/sửa thành công để đóng form

  const TransactionState({
    this.isLoading = false,
    this.transactions = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  TransactionState copyWith({
    bool? isLoading,
    List<TransactionEntity>? transactions,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage, 
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, transactions, errorMessage, isSuccess];
}

// 2. Notifier
class TransactionNotifier extends StateNotifier<TransactionState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final AddTransactionUseCase _addTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  // Thêm UseCase update
  final UpdateTransactionUseCase _updateTransactionUseCase;

  TransactionNotifier(
    this._getTransactionsUseCase,
    this._addTransactionUseCase,
    this._deleteTransactionUseCase,
    this._updateTransactionUseCase, // Inject vào constructor
  ) : super(const TransactionState());

  // Lấy danh sách giao dịch
  Future<void> fetchTransactions(String userId) async {
    // Chỉ hiện loading nếu list đang rỗng (để tránh nháy màn hình khi refresh)
    if (state.transactions.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    final result = await _getTransactionsUseCase(userId);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (data) => state = state.copyWith(isLoading: false, transactions: data),
    );
  }

  // Thêm giao dịch
  Future<void> addTransaction(TransactionEntity transaction) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final result = await _addTransactionUseCase(transaction);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (success) async {
        await fetchTransactions(transaction.userId);
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  // --- HÀM MỚI: Cập nhật giao dịch ---
  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final result = await _updateTransactionUseCase(transaction);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (success) async {
        // Sau khi update thành công, tải lại danh sách mới nhất
        await fetchTransactions(transaction.userId);
        // Báo hiệu thành công để đóng form
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  // Xóa giao dịch
  Future<void> deleteTransaction(String transactionId, String userId) async {
    // Optimistic UI: Xóa trên UI trước cho mượt
    final oldList = state.transactions;
    final newList = oldList.where((t) => t.id != transactionId).toList();
    state = state.copyWith(transactions: newList);

    final result = await _deleteTransactionUseCase(transactionId, userId);
    
    result.fold(
      (failure) {
        // Nếu lỗi thì revert lại danh sách cũ và báo lỗi
        state = state.copyWith(transactions: oldList, errorMessage: failure.message);
      },
      (success) => null, // Thành công thì không cần làm gì thêm
    );
  }

  // Clear all transactions (when wallet is deleted)
  void clearTransactions() {
    state = const TransactionState(transactions: []);
  }
}

// 3. Provider chính
final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(
    ref.read(getTransactionsUseCaseProvider),
    ref.read(addTransactionUseCaseProvider),
    ref.read(deleteTransactionUseCaseProvider),
    ref.read(updateTransactionUseCaseProvider), // Thêm provider update vào đây
  );
});