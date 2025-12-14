import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;
  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(String userId) {
    return repository.getTransactions(userId);
  }
}