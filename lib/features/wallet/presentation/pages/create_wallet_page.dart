import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/utils/currency_input_formatter.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:finance_app/features/auth/data/services/auth_service.dart';
import 'package:finance_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:finance_app/features/home/presentation/pages/home_page.dart';
import '../providers/wallet_notifier.dart';
import '../providers/wallet_providers.dart';

class CreateWalletPage extends ConsumerStatefulWidget {
  final bool isOnboarding; // true nếu là lần đầu đăng nhập, false nếu từ Settings

  const CreateWalletPage({
    super.key,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends ConsumerState<CreateWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Ví tiền mặt');
  final _initialBalanceController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    // Reset wallet state when page opens to clear stale isSuccess flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletNotifierProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletNotifierProvider);

    return Scaffold(
      appBar: widget.isOnboarding ? null : AppBar(
        title: const Text('Tạo Ví'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isOnboarding) ...[
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tạo Ví của bạn',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo ví để theo dõi thu chi của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                ],

                // Tên ví
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ví',
                    hintText: 'Ví tiền mặt',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên ví';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Số dư ban đầu
                TextFormField(
                  controller: _initialBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Số dư ban đầu',
                    hintText: '0',
                    prefixIcon: Icon(Icons.money),
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số dư';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Buttons
                if (walletState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _createWallet,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Tạo Ví',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                if (walletState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    walletState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final userId = authState.user.id;
    final name = _nameController.text.trim();
    final balanceText = _initialBalanceController.text.replaceAll('.', '');
    final initialBalance = double.tryParse(balanceText) ?? 0;

    // Mark onboarding completed BEFORE creating wallet (if onboarding flow)
    if (widget.isOnboarding) {
      final authService = ref.read(authServiceProvider);
      await authService.markWalletOnboardingCompleted(userId);
    }

    // Create wallet
    await ref.read(walletNotifierProvider.notifier).createWallet(
      userId,
      name,
      initialBalance,
    );

    // Check if creation was successful
    final finalState = ref.read(walletNotifierProvider);
    if (finalState.isSuccess && mounted) {
      // Navigate after successful creation
      if (widget.isOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }
}
