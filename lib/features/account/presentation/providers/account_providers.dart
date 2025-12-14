import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/providers/firebase_providers.dart';

// SỬA LẠI ĐƯỜNG DẪN IMPORT (Thêm ../)
import '../../data/services/account_service.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';

// Service
final accountServiceProvider = Provider<AccountService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);
  return AccountService(firebaseAuth, firestore);
});

// Repository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final service = ref.read(accountServiceProvider);
  return AccountRepositoryImpl(service);
});

// UseCase
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(accountRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.read(accountRepositoryProvider));
});