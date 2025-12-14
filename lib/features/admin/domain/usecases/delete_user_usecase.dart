import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/admin_repository.dart';

class DeleteUserUseCase {
  final AdminRepository repository;

  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.deleteUser(userId);
  }
}
