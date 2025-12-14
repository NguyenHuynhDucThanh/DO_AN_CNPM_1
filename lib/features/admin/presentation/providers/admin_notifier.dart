import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/features/transaction/domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/toggle_lock_user_usecase.dart';
import '../../domain/usecases/get_all_transactions_usecase.dart';
import '../../domain/usecases/get_user_transactions_usecase.dart';
import 'admin_providers.dart';

// ===== USER MANAGEMENT STATE =====
class UserManagementState {
  final List<UserEntity> users;
  final bool isLoading;
  final String? errorMessage;

  UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  UserManagementState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final DeleteUserUseCase _deleteUserUseCase;
  final ToggleLockUserUseCase _toggleLockUserUseCase;

  UserManagementNotifier(
    this._getAllUsersUseCase,
    this._deleteUserUseCase,
    this._toggleLockUserUseCase,
  ) : super(UserManagementState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _getAllUsersUseCase();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (users) => state = state.copyWith(
        users: users,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> deleteUser(String userId) async {
    final result = await _deleteUserUseCase(userId);
    
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {
        // Xóa user khỏi list local
        final updatedUsers = state.users.where((u) => u.id != userId).toList();
        state = state.copyWith(users: updatedUsers, errorMessage: null);
      },
    );
  }

  Future<void> toggleLockUser(String userId, bool isLocked) async {
    final result = await _toggleLockUserUseCase(userId, isLocked);
    
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {
        // Cập nhật user trong list local
        final updatedUsers = state.users.map((user) {
          if (user.id == userId) {
            return UserEntity(
              id: user.id,
              email: user.email,
              displayName: user.displayName,
              role: user.role,
              isLocked: isLocked,
            );
          }
          return user;
        }).toList();
        state = state.copyWith(users: updatedUsers, errorMessage: null);
      },
    );
  }
}

final userManagementNotifierProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(
    ref.read(getAllUsersUseCaseProvider),
    ref.read(deleteUserUseCaseProvider),
    ref.read(toggleLockUserUseCaseProvider),
  );
});

// ===== TRANSACTION MANAGEMENT STATE =====
class TransactionManagementState {
  final List<TransactionEntity> transactions;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedUserId;

  TransactionManagementState({
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedUserId,
  });

  TransactionManagementState copyWith({
    List<TransactionEntity>? transactions,
    bool? isLoading,
    String? errorMessage,
    String? selectedUserId,
  }) {
    return TransactionManagementState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedUserId: selectedUserId ?? this.selectedUserId,
    );
  }
}

class TransactionManagementNotifier extends StateNotifier<TransactionManagementState> {
  final GetAllTransactionsUseCase _getAllTransactionsUseCase;
  final GetUserTransactionsUseCase _getUserTransactionsUseCase;

  TransactionManagementNotifier(
    this._getAllTransactionsUseCase,
    this._getUserTransactionsUseCase,
  ) : super(TransactionManagementState());

  Future<void> loadAllTransactions() async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedUserId: null);
    
    final result = await _getAllTransactionsUseCase();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (transactions) => state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> loadUserTransactions(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedUserId: userId);
    
    final result = await _getUserTransactionsUseCase(userId);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (transactions) => state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }
}

final transactionManagementNotifierProvider =
    StateNotifierProvider<TransactionManagementNotifier, TransactionManagementState>((ref) {
  return TransactionManagementNotifier(
    ref.read(getAllTransactionsUseCaseProvider),
    ref.read(getUserTransactionsUseCaseProvider),
  );
});
