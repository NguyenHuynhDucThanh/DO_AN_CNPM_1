import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/features/auth/domain/entities/user_entity.dart';
import '../providers/account_notifier.dart';

class UpdateProfileDialog extends ConsumerStatefulWidget {
  final UserEntity currentUser;

  const UpdateProfileDialog({super.key, required this.currentUser});

  @override
  ConsumerState<UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends ConsumerState<UpdateProfileDialog> {
  late TextEditingController _displayNameController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _changePassword = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.currentUser.displayName ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountNotifierProvider);

    // Lắng nghe state để đóng dialog hoặc hiện lỗi
    ref.listen(accountNotifierProvider, (previous, next) {
      if (next is AccountUpdateSuccess) {
        Navigator.pop(context); // Đóng dialog khi thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
        );
        ref.read(accountNotifierProvider.notifier).resetState(); // Reset state
      } else if (next is AccountUpdateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
        ref.read(accountNotifierProvider.notifier).resetState(); // Reset state
      }
    });

    return AlertDialog(
      title: const Text('Cập nhật hồ sơ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Đổi mật khẩu'),
              value: _changePassword,
              tristate: false,
              onChanged: accountState is AccountUpdateLoading ? null : (value) {
                setState(() {
                  _changePassword = value ?? false;
                  if (!_changePassword) {
                    _oldPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  }
                });
              },
            ),
            if (_changePassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
            if (accountState is AccountUpdateLoading) // Hiện loading khi đang cập nhật
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: LoadingWidget(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (accountState is! AccountUpdateLoading) { // Không cho bấm khi đang loading
              Navigator.pop(context);
            }
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: accountState is AccountUpdateLoading ? null : () { // Disable khi đang loading
            final newName = _displayNameController.text.trim();
            
            // Validate tên hiển thị
            if (newName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tên hiển thị không được để trống')),
              );
              return;
            }

            // Validate mật khẩu nếu checkbox được tích
            if (_changePassword) {
              final oldPassword = _oldPasswordController.text;
              final newPassword = _newPasswordController.text;
              final confirmPassword = _confirmPasswordController.text;

              if (oldPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mật khẩu hiện tại')),
                );
                return;
              }

              if (newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mật khẩu mới')),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 6 ký tự')),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu mới và xác nhận không khớp')),
                );
                return;
              }

              // Gọi API đổi mật khẩu
              ref.read(accountNotifierProvider.notifier).changePassword(
                    oldPassword,
                    newPassword,
                  );
            } else {
              // Chỉ cập nhật tên nếu có thay đổi
              if (newName == widget.currentUser.displayName) {
                Navigator.pop(context); // Đóng nếu không có gì thay đổi
                return;
              }

              ref.read(accountNotifierProvider.notifier).updateDisplayName(
                    widget.currentUser.id,
                    newName,
                  );
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}