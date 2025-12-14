import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../services/admin_service.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminService service;

  AdminRepositoryImpl(this.service);

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final users = await service.getAllUsers();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String userId) async {
    try {
      final user = await service.getUserById(userId);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await service.updateUser(userId, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await service.deleteUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLockUser(String userId, bool isLocked) async {
    try {
      await service.toggleLockUser(userId, isLocked);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions() async {
    try {
      final transactions = await service.getAllTransactions();
      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByUserId(String userId) async {
    try {
      final transactions = await service.getTransactionsByUserId(userId);
      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
