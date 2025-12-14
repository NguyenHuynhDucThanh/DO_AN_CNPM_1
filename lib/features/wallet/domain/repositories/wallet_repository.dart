import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity?>> getWallet(String userId);
  Future<Either<Failure, void>> createWallet(WalletEntity wallet);
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet);
  Future<Either<Failure, void>> deleteWallet(String userId);
}
