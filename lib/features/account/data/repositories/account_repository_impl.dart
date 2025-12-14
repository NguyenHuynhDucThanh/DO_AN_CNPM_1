import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../services/account_service.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountService service;

  AccountRepositoryImpl(this.service);

  @override
  Future<Either<Failure, UserEntity>> updateDisplayName(String userId, String newDisplayName) async {
    try {
      final updatedUser = await service.updateDisplayName(userId, newDisplayName);
      return Right(updatedUser);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi xác thực khi cập nhật hồ sơ'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword) async {
    try {
      await service.changePassword(oldPassword, newPassword);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Lỗi xác thực khi đổi mật khẩu'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}