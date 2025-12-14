import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, Unit>> call() {
    return repository.logout();
  }
}