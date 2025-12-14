import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/account_repository.dart';

class ChangePasswordUseCase {
  final AccountRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String oldPassword, String newPassword) {
    return repository.changePassword(oldPassword, newPassword);
  }
}
