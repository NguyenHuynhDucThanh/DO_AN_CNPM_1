import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import '../repositories/account_repository.dart';

class UpdateProfileUseCase {
  final AccountRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String userId, String newDisplayName) {
    return repository.updateDisplayName(userId, newDisplayName);
  }
}