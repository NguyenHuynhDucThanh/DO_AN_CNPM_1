import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/auth/data/models/user_model.dart';
import 'package:finance_app/features/transaction/data/models/transaction_model.dart';

class AdminService {
  final FirebaseFirestore _firestore;

  AdminService(this._firestore);

  // ===== USER MANAGEMENT =====
  
  /// Lấy tất cả users từ Firestore
  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  /// Lấy thông tin 1 user theo ID
  Future<UserModel> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User không tồn tại');
    }
    return UserModel.fromFirestore(doc);
  }

  /// Cập nhật thông tin user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  /// Xóa user và tất cả transactions của user đó
  Future<void> deleteUser(String userId) async {
    // Xóa tất cả transactions của user từ subcollection
    final transactionsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();
    
    final batch = _firestore.batch();
    for (var doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Xóa user document
    batch.delete(_firestore.collection('users').doc(userId));
    
    await batch.commit();
  }

  /// Khóa/Mở khóa user
  Future<void> toggleLockUser(String userId, bool isLocked) async {
    await _firestore.collection('users').doc(userId).update({
      'isLocked': isLocked,
    });
  }

  // ===== TRANSACTION MANAGEMENT =====
  
  /// Lấy tất cả transactions từ TẤT CẢ users
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      print('[AdminService] Fetching all transactions from all users');
      
      // Lấy tất cả users trước
      final usersSnapshot = await _firestore.collection('users').get();
      print('[AdminService] Found ${usersSnapshot.docs.length} users');
      
      final List<TransactionModel> allTransactions = [];
      
      // Với mỗi user, lấy transactions của họ
      for (var userDoc in usersSnapshot.docs) {
        final userTransactions = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('transactions')
            .get();
        
        print('[AdminService] User ${userDoc.id}: ${userTransactions.docs.length} transactions');
        
        for (var txDoc in userTransactions.docs) {
          allTransactions.add(TransactionModel.fromFirestore(txDoc));
        }
      }
      
      // Sort ở client-side
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      print('[AdminService] Total: ${allTransactions.length} transactions');
      return allTransactions;
    } catch (e) {
      print('[AdminService] Error in getAllTransactions: $e');
      rethrow;
    }
  }

  /// Lấy transactions của 1 user từ subcollection
  Future<List<TransactionModel>> getTransactionsByUserId(String userId) async {
    try {
      print('[AdminService] Fetching transactions for userId: $userId');
      
      // Query từ subcollection: users/{userId}/transactions
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();
      
      print('[AdminService] Found ${querySnapshot.docs.length} transactions');
      
      final transactions = querySnapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              print('[AdminService] Error parsing transaction ${doc.id}: $e');
              rethrow;
            }
          })
          .toList();
      
      // Sort ở client-side
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      print('[AdminService] Returning ${transactions.length} sorted transactions');
      return transactions;
    } catch (e) {
      print('[AdminService] Error in getTransactionsByUserId: $e');
      rethrow;
    }
  }
}
