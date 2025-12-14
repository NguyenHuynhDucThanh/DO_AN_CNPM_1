import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';

abstract class AdminRepository {
  // User Management
  Future<Either<Failure, List<UserEntity>>> getAllUsers();
  Future<Either<Failure, UserEntity>> getUserById(String userId);
  Future<Either<Failure, void>> updateUser(String userId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteUser(String userId);
  Future<Either<Failure, void>> toggleLockUser(String userId, bool isLocked);
  
  // Transaction Management
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions();
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByUserId(String userId);
}
