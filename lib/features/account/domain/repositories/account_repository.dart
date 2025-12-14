import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart'; // Sử dụng lại UserEntity

abstract class AccountRepository {
  // Cập nhật tên hiển thị của người dùng
  Future<Either<Failure, UserEntity>> updateDisplayName(String userId, String newDisplayName);

  // Đổi mật khẩu
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword);

  // Có thể thêm các hàm khác như: getProfile, uploadAvatar...
}