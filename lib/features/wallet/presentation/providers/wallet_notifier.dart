import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/update_wallet_usecase.dart';
import '../../domain/usecases/delete_wallet_usecase.dart';
import '../../../transaction/presentation/providers/transaction_notifier.dart';

class WalletState extends Equatable {
  final bool isLoading;
  final WalletEntity? wallet;
  final String? errorMessage;
  final bool isSuccess;

  const WalletState({
    this.isLoading = false,
    this.wallet,
    this.errorMessage,
    this.isSuccess = false,
  });

  WalletState copyWith({
    bool? isLoading,
    WalletEntity? wallet,
    String? errorMessage,
    bool? isSuccess,
    bool clearWallet = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      wallet: clearWallet ? null : (wallet ?? this.wallet),
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, wallet, errorMessage, isSuccess];
}

class WalletNotifier extends StateNotifier<WalletState> {
  final GetWalletUseCase _getWalletUseCase;
  final CreateWalletUseCase _createWalletUseCase;
  final UpdateWalletUseCase _updateWalletUseCase;
  final DeleteWalletUseCase _deleteWalletUseCase;

  WalletNotifier(
    this._getWalletUseCase,
    this._createWalletUseCase,
    this._updateWalletUseCase,
    this._deleteWalletUseCase,
  ) : super(const WalletState());

  Future<void> loadWallet(String userId) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _getWalletUseCase(userId);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (wallet) => state = state.copyWith(
        isLoading: false,
        wallet: wallet,
      ),
    );
  }

  Future<void> createWallet(String userId, String name, double initialBalance) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final wallet = WalletEntity(
      userId: userId,
      name: name,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );
    
    final result = await _createWalletUseCase(wallet);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(
          isLoading: false,
          wallet: wallet,
          isSuccess: true,
        );
      },
    );
  }

  Future<void> updateWallet(String userId, String name, double initialBalance) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final wallet = WalletEntity(
      userId: userId,
      name: name,
      initialBalance: initialBalance,
      createdAt: state.wallet?.createdAt ?? DateTime.now(),
      isActive: state.wallet?.isActive ?? true,
    );
    
    final result = await _updateWalletUseCase(wallet);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(
          isLoading: false,
          wallet: wallet,
          isSuccess: true,
        );
      },
    );
  }

  Future<void> deleteWallet(String userId) async {
    state = state.copyWith(isLoading: true, isSuccess: false);
    
    final result = await _deleteWalletUseCase(userId);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearWallet: true,
          isSuccess: true,
        );
      },
    );
  }

  // Reset state (clear isSuccess flag)
  void resetState() {
    state = state.copyWith(isSuccess: false);
  }
}
