import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository repository;

  GetWalletUseCase(this.repository);

  Future<Either<Failure, WalletEntity?>> call(String userId) {
    return repository.getWallet(userId);
  }
}
