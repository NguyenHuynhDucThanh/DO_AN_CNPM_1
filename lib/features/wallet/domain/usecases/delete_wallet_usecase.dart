import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class DeleteWalletUseCase {
  final WalletRepository repository;

  DeleteWalletUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.deleteWallet(userId);
  }
}
