import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  // Lấy danh sách giao dịch của user
  Future<Either<Failure, List<TransactionEntity>>> getTransactions(String userId);
  
  // Thêm giao dịch mới
  Future<Either<Failure, Unit>> addTransaction(TransactionEntity transaction);

  // Sửa giao dịch
  Future<Either<Failure, Unit>> updateTransaction(TransactionEntity transaction);

  // Xóa giao dịch
  Future<Either<Failure, Unit>> deleteTransaction(String transactionId, String userId);
}