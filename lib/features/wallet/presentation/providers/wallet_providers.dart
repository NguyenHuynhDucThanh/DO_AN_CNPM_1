import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../data/services/wallet_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/update_wallet_usecase.dart';
import '../../domain/usecases/delete_wallet_usecase.dart';
import 'wallet_notifier.dart';

// Service Provider
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(
    FirebaseFirestore.instance,
    ref.read(transactionServiceProvider),
  );
});

// Repository Provider
final walletRepositoryProvider = Provider((ref) {
  return WalletRepositoryImpl(ref.read(walletServiceProvider));
});

// Use Cases Providers
final getWalletUseCaseProvider = Provider((ref) {
  return GetWalletUseCase(ref.read(walletRepositoryProvider));
});

final createWalletUseCaseProvider = Provider((ref) {
  return CreateWalletUseCase(ref.read(walletRepositoryProvider));
});

final updateWalletUseCaseProvider = Provider((ref) {
  return UpdateWalletUseCase(ref.read(walletRepositoryProvider));
});

final deleteWalletUseCaseProvider = Provider((ref) {
  return DeleteWalletUseCase(ref.read(walletRepositoryProvider));
});

// Notifier Provider
final walletNotifierProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(
    ref.read(getWalletUseCaseProvider),
    ref.read(createWalletUseCaseProvider),
    ref.read(updateWalletUseCaseProvider),
    ref.read(deleteWalletUseCaseProvider),
  );
});
