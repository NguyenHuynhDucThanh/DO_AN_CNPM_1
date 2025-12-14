import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/providers/firebase_providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

// 1. Provider cho Service
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);
  return AuthService(firebaseAuth, firestore);
});

// 2. Provider cho Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthRepositoryImpl(authService);
});

// 3. Provider cho UseCases
final loginUseCaseProvider = Provider((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});