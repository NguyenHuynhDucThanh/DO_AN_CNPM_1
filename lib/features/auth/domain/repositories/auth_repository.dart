import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Đăng nhập trả về Lỗi (Failure) hoặc User (UserEntity)
  Future<Either<Failure, UserEntity>> login(String email, String password);
  
  // Đăng ký
  Future<Either<Failure, UserEntity>> register(String email, String password, {String? displayName, String? phoneNumber});
  
  // Đăng xuất (Trả về void nên dùng Unit của dartz)
  Future<Either<Failure, Unit>> logout();
  
  // Lấy user hiện tại (nếu đã đăng nhập trước đó)
  Future<Either<Failure, UserEntity>> getCurrentUser();
}