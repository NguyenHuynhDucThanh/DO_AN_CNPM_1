import 'package:equatable/equatable.dart';

// Định nghĩa loại giao dịch: Thu hoặc Chi
enum TransactionType { income, expense }

class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String category; // Tạm thời dùng String, sau này nâng cấp lên CategoryEntity
  final String title;
  final DateTime date;
  final String? note;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.title,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, userId, amount, type, category, date, note];
}