import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;
  AddTransactionUseCase(this.repository);

  Future<Either<Failure, Unit>> call(TransactionEntity transaction) {
    return repository.addTransaction(transaction);
  }
}