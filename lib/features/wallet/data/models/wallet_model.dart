import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    required super.name,
    required super.initialBalance,
    required super.createdAt,
    super.isActive,
  });

  // Convert from Firestore document
  factory WalletModel.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception('Wallet data is null');
    }

    return WalletModel(
      userId: userId,
      name: data['name'] ?? 'Ví của tôi',
      initialBalance: (data['initialBalance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'initialBalance': initialBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
