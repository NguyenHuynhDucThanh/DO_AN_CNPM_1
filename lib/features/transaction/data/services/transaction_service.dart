import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore;

  TransactionService(this._firestore);

  // Lấy Collection Reference tới transactions của user cụ thể
  CollectionReference _getUserTransactions(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snapshot = await _getUserTransactions(userId)
        .orderBy('date', descending: true) // Sắp xếp ngày mới nhất lên đầu
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    // Dùng id từ entity (UUID) làm doc id: gọi lặp / retry ghi cùng doc → không sinh bản copy mới.
    await _getUserTransactions(transaction.userId)
        .doc(transaction.id)
        .set(transaction.toDocument());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _getUserTransactions(transaction.userId)
        .doc(transaction.id)
        .update(transaction.toDocument());
  }

  Future<void> deleteTransaction(String transactionId, String userId) async {
    await _getUserTransactions(userId).doc(transactionId).delete();
  }

  // Delete ALL transactions for a user (when deleting wallet)
  Future<void> deleteAllTransactions(String userId) async {
    final snapshot = await _getUserTransactions(userId).get();
    final batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}