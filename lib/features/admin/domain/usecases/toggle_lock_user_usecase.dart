import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class ToggleLockUserUseCase {
  final AdminRepository repository;

  ToggleLockUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, bool isLocked) {
    return repository.toggleLockUser(userId, isLocked);
  }
}
