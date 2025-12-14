import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import '../repositories/admin_repository.dart';

class GetUserTransactionsUseCase {
  final AdminRepository repository;

  GetUserTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(String userId) {
    return repository.getTransactionsByUserId(userId);
  }
}
