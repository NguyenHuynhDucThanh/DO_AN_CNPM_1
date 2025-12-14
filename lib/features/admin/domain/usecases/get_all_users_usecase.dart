import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import '../repositories/admin_repository.dart';

class GetAllUsersUseCase {
  final AdminRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<Either<Failure, List<UserEntity>>> call() {
    return repository.getAllUsers();
  }
}
