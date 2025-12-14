import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String email, String password, {String? displayName, String? phoneNumber}) {
    return repository.register(email, password, displayName: displayName, phoneNumber: phoneNumber);
  }
}