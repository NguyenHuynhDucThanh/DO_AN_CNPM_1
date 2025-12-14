import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class CreateWalletUseCase {
  final WalletRepository repository;

  CreateWalletUseCase(this.repository);

  Future<Either<Failure, void>> call(WalletEntity wallet) {
    return repository.createWallet(wallet);
  }
}
