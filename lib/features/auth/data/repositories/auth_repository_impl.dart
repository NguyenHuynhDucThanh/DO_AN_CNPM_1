import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;

  AuthRepositoryImpl(this.authService);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final userModel = await authService.login(email, password);
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Đăng nhập thất bại'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(String email, String password, {String? displayName, String? phoneNumber}) async {
    try {
      final userModel = await authService.register(email, password, displayName: displayName, phoneNumber: phoneNumber);
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Đăng ký thất bại'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await authService.logout();
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await authService.getCurrentUserModel();
      if (userModel != null) {
        return Right(userModel);
      } else {
        return const Left(AuthFailure('Người dùng chưa đăng nhập'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
