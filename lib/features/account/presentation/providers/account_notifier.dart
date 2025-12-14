import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';

// SỬA LẠI ĐƯỜNG DẪN IMPORT (Thêm ../)
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import 'account_providers.dart';

// 1. Trạng thái Account Update
abstract class AccountUpdateState {}
class AccountUpdateInitial extends AccountUpdateState {}
class AccountUpdateLoading extends AccountUpdateState {}
class AccountUpdateSuccess extends AccountUpdateState {
  final UserEntity user;
  AccountUpdateSuccess(this.user);
}
class AccountUpdateError extends AccountUpdateState {
  final String message;
  AccountUpdateError(this.message);
}

// 2. Notifier
class AccountNotifier extends StateNotifier<AccountUpdateState> {
  final UpdateProfileUseCase _updateProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final AuthNotifier _authNotifier; 

  AccountNotifier(this._updateProfileUseCase, this._changePasswordUseCase, this._authNotifier) : super(AccountUpdateInitial());

  Future<void> updateDisplayName(String userId, String newDisplayName) async {
    state = AccountUpdateLoading();
    final result = await _updateProfileUseCase(userId, newDisplayName);

    result.fold(
      (failure) => state = AccountUpdateError(failure.message),
      (user) {
        // Cập nhật thành công -> Báo cho AuthNotifier biết để đổi tên trên AppBar
        _authNotifier.updateUser(user);
        state = AccountUpdateSuccess(user);
      },
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    state = AccountUpdateLoading();
    final result = await _changePasswordUseCase(oldPassword, newPassword);

    result.fold(
      (failure) => state = AccountUpdateError(failure.message),
      (_) {
        // Đổi mật khẩu thành công
        // Lấy user hiện tại từ AuthNotifier state
        final authState = _authNotifier.state;
        if (authState is AuthAuthenticated) {
          state = AccountUpdateSuccess(authState.user);
        } else {
          state = AccountUpdateError('Không tìm thấy thông tin người dùng');
        }
      },
    );
  }

  void resetState() {
    state = AccountUpdateInitial();
  }
}

// 3. Provider
final accountNotifierProvider = StateNotifierProvider<AccountNotifier, AccountUpdateState>((ref) {
  return AccountNotifier(
    ref.read(updateProfileUseCaseProvider),
    ref.read(changePasswordUseCaseProvider),
    ref.read(authNotifierProvider.notifier), 
  );
});