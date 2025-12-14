import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.category,
    required super.title,
    required super.date,
    super.note,
  });

  // Từ Firestore Document -> Model
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: data['category'] ?? 'Khác',
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  // Từ Model -> Map (để lưu lên Firestore)
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'title': title,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  // Helper để convert từ Entity sang Model
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      type: entity.type,
      category: entity.category,
      title: entity.title,
      date: entity.date,
      note: entity.note,
    );
  }
}