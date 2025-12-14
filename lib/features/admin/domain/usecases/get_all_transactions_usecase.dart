import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import '../repositories/admin_repository.dart';

class GetAllTransactionsUseCase {
  final AdminRepository repository;

  GetAllTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call() {
    return repository.getAllTransactions();
  }
}
