import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String userId;
  final String name;
  final double initialBalance;
  final DateTime createdAt;
  final bool isActive;

  const WalletEntity({
    required this.userId,
    required this.name,
    required this.initialBalance,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [userId, name, initialBalance, createdAt, isActive];
}
