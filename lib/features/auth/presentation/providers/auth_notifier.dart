import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_providers.dart';

// Định nghĩa trạng thái
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthNotifier(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
  ) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    final result = await _loginUseCase(email, password);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
    );
  }


  Future<void> register(String email, String password, {String? displayName, String? phoneNumber}) async {
    state = AuthLoading();
    final result = await _registerUseCase(email, password, displayName: displayName, phoneNumber: phoneNumber);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
    );
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _logoutUseCase();
    state = AuthUnauthenticated();
  }

  // --- HÀM MỚI THÊM (Theo bước 2.2) ---
  // Dùng để cập nhật thông tin User trong State mà không cần đăng nhập lại
  void updateUser(UserEntity user) {
    // Chỉ cập nhật nếu đang ở trạng thái đã đăng nhập
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }
}

// Provider chính để UI sử dụng
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(loginUseCaseProvider),
    ref.read(registerUseCaseProvider),
    ref.read(logoutUseCaseProvider),
  );
});