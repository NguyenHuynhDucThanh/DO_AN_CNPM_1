import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/providers/firebase_providers.dart';
import '../../data/services/admin_service.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/toggle_lock_user_usecase.dart';
import '../../domain/usecases/get_all_transactions_usecase.dart';
import '../../domain/usecases/get_user_transactions_usecase.dart';

// Service
final adminServiceProvider = Provider<AdminService>((ref) {
  final firestore = ref.read(firestoreProvider);
  return AdminService(firestore);
});

// Repository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final service = ref.read(adminServiceProvider);
  return AdminRepositoryImpl(service);
});

// Use Cases
final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  return GetAllUsersUseCase(ref.read(adminRepositoryProvider));
});

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  return DeleteUserUseCase(ref.read(adminRepositoryProvider));
});

final toggleLockUserUseCaseProvider = Provider<ToggleLockUserUseCase>((ref) {
  return ToggleLockUserUseCase(ref.read(adminRepositoryProvider));
});

final getAllTransactionsUseCaseProvider = Provider<GetAllTransactionsUseCase>((ref) {
  return GetAllTransactionsUseCase(ref.read(adminRepositoryProvider));
});

final getUserTransactionsUseCaseProvider = Provider<GetUserTransactionsUseCase>((ref) {
  return GetUserTransactionsUseCase(ref.read(adminRepositoryProvider));
});
