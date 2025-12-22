import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/widgets/error_widget.dart';
// Import HomePage để điều hướng
import '../../../home/presentation/pages/home_page.dart';
// Import AdminHomePage
import '../../../admin/presentation/pages/admin_home_page.dart';
// Import CreateWalletPage
import '../../../wallet/presentation/pages/create_wallet_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isLogin = true; // Chuyển đổi giữa Login và Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state
    final authState = ref.watch(authNotifierProvider);

    // Lắng nghe sự kiện để điều hướng
    ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        // Đăng nhập thành công
        print('[AuthPage] Authenticated as: ${next.user.email}');
        print('[AuthPage] isAdmin: ${next.user.isAdmin}');

        // Chuyển hướng dựa trên role
        Widget targetPage;
        
        if (next.user.isAdmin) {
          // Admin → AdminHomePage
          targetPage = const AdminHomePage();
        } else {
          // User → HomePage (không cần ví)
          targetPage = const HomePage();
        }
        
        // Delay navigation to prevent disposed view error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => targetPage),
          );
        });
      } else if (next is AuthError) {
        // Hiển thị lỗi bằng SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            // Nếu đang xử lý thì hiện loading
            if (authState is AuthLoading) {
              return const LoadingWidget();
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hiển thị lỗi ngay trên UI (nếu thích, hoặc dùng SnackBar như trên cũng được)
                if (authState is AuthError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: AppErrorWidget(message: authState.message),
                  ),
                
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                // Display Name (only for registration)
                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Nhập tên của bạn',
                    ),
                  ),
                ],
                
                // Phone Number (optional, only for registration)
                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại (tùy chọn)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: 'Nhập số điện thoại',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
                
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();
                      final displayName = _displayNameController.text.trim();
                      final phone = _phoneController.text.trim();
                      
                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                        );
                        return;
                      }
                      
                      // Validate display name for registration
                      if (!isLogin && displayName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Vui lòng nhập tên hiển thị')),
                        );
                        return;
                      }

                      if (isLogin) {
                        ref.read(authNotifierProvider.notifier).login(email, password);
                      } else {
                        ref.read(authNotifierProvider.notifier).register(
                          email, 
                          password,
                          displayName: displayName.isNotEmpty ? displayName : null,
                          phoneNumber: phone.isNotEmpty ? phone : null,
                        );
                      }
                    },
                    child: Text(isLogin ? 'Đăng nhập' : 'Đăng ký', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      // Xóa lỗi cũ khi chuyển tab
                      if (authState is AuthError) {
                         // Reset state về initial nếu muốn, nhưng ở đây ta chỉ cần UI update
                      }
                    });
                  },
                  child: Text(isLogin
                      ? 'Chưa có tài khoản? Đăng ký ngay'
                      : 'Đã có tài khoản? Đăng nhập'),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}