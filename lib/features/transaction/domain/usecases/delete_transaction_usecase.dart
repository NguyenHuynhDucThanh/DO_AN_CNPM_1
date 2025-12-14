import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String transactionId, String userId) {
    return repository.deleteTransaction(transactionId, userId);
  }
}