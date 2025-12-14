import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../services/wallet_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletService _walletService;

  WalletRepositoryImpl(this._walletService);

  @override
  Future<Either<Failure, WalletEntity?>> getWallet(String userId) async {
    try {
      final wallet = await _walletService.getWallet(userId);
      return Right(wallet);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createWallet(WalletEntity wallet) async {
    try {
      await _walletService.createWallet(
        wallet.userId,
        wallet.name,
        wallet.initialBalance,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet) async {
    try {
      await _walletService.updateWallet(
        wallet.userId,
        wallet.name,
        wallet.initialBalance,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWallet(String userId) async {
    try {
      await _walletService.deleteWallet(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
