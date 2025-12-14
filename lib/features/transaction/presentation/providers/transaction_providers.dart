import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/providers/firebase_providers.dart';
import '../../data/services/transaction_service.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';

// 1. Service
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final firestore = ref.read(firestoreProvider);
  return TransactionService(firestore);
});

// 2. Repository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final service = ref.read(transactionServiceProvider);
  return TransactionRepositoryImpl(service);
});

// 3. UseCases
final getTransactionsUseCaseProvider = Provider((ref) {
  return GetTransactionsUseCase(ref.read(transactionRepositoryProvider));
});

final addTransactionUseCaseProvider = Provider((ref) {
  return AddTransactionUseCase(ref.read(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider = Provider((ref) {
  return UpdateTransactionUseCase(ref.read(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider((ref) {
  return DeleteTransactionUseCase(ref.read(transactionRepositoryProvider));
});