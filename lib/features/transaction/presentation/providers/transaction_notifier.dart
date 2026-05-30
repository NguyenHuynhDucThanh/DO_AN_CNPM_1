import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import 'transaction_providers.dart';

class TransactionState extends Equatable {
  final bool isLoading;
  final List<TransactionEntity> transactions;
  final String? errorMessage;
  final bool isSuccess;

  const TransactionState({
    this.isLoading = false,
    this.transactions = const[],
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

class TransactionNotifier extends StateNotifier<TransactionState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final AddTransactionUseCase _addTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  final UpdateTransactionUseCase _updateTransactionUseCase;

  TransactionNotifier(
    this._getTransactionsUseCase,
    this._addTransactionUseCase,
    this._deleteTransactionUseCase,
    this._updateTransactionUseCase,
  ) : super(const TransactionState());

  /// Xóa cờ success/error khi mở lại form (tránh ref.listen hiểu nhầm chuyển trạng thái).
  void resetUiFeedback() {
    state = TransactionState(
      isLoading: state.isLoading,
      transactions: state.transactions,
      errorMessage: null,
      isSuccess: false,
    );
  }

  Future<void> fetchTransactions(String userId) async {
    if (state.transactions.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    final result = await _getTransactionsUseCase(userId);
    
    // THÊM DÒNG NÀY: Kiểm tra xem Notifier đã bị hủy chưa trước khi set state
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (data) => state = state.copyWith(isLoading: false, transactions: data),
    );
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final result = await _addTransactionUseCase(transaction);
    
    if (!mounted) return; // Kiểm tra

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (success) async {
        await fetchTransactions(transaction.userId);

        if (!mounted) return; // Kiểm tra lại sau khi fetch xong
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final result = await _updateTransactionUseCase(transaction);
    
    if (!mounted) return; // Kiểm tra

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (success) async {
        await fetchTransactions(transaction.userId);

        if (!mounted) return; // Kiểm tra
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  Future<void> deleteTransaction(String transactionId, String userId) async {
    final oldList = state.transactions;
    final newList = oldList.where((t) => t.id != transactionId).toList();
    state = state.copyWith(transactions: newList);

    final result = await _deleteTransactionUseCase(transactionId, userId);
    
    if (!mounted) return; // Kiểm tra

    result.fold(
      (failure) {
        state = state.copyWith(transactions: oldList, errorMessage: failure.message);
      },
      (success) => null,
    );
  }

  void clearTransactions() {
    state = const TransactionState();
  }
}

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(
    ref.read(getTransactionsUseCaseProvider),
    ref.read(addTransactionUseCaseProvider),
    ref.read(deleteTransactionUseCaseProvider),
    ref.read(updateTransactionUseCaseProvider),
  );
});
