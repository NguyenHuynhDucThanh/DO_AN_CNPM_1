import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionService service;

  TransactionRepositoryImpl(this.service);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions(String userId) async {
    try {
      final models = await service.getTransactions(userId);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await service.addTransaction(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await service.updateTransaction(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String transactionId, String userId) async {
    try {
      await service.deleteTransaction(transactionId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}