import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../../../transaction/data/services/transaction_service.dart';

class WalletService {
  final FirebaseFirestore _firestore;
  final TransactionService _transactionService;

  WalletService(this._firestore, this._transactionService);

  // Get wallet for a user
  Future<WalletModel?> getWallet(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).collection('wallet').doc('default').get();
    
    if (!doc.exists) {
      return null;
    }
    
    return WalletModel.fromFirestore(doc, userId);
  }

  // Create wallet
  Future<void> createWallet(String userId, String name, double initialBalance) async {
    final walletData = {
      'name': name,
      'initialBalance': initialBalance,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await _firestore.collection('users').doc(userId).collection('wallet').doc('default').set(walletData);
  }

  // Update wallet
  Future<void> updateWallet(String userId, String name, double initialBalance) async {
    await _firestore.collection('users').doc(userId).collection('wallet').doc('default').update({
      'name': name,
      'initialBalance': initialBalance,
    });
  }

  // Delete wallet AND all transactions (hard delete)
  Future<void> deleteWallet(String userId) async {
    // Delete wallet document
    await _firestore.collection('users').doc(userId).collection('wallet').doc('default').delete();
    
    // Delete all transactions
    await _transactionService.deleteAllTransactions(userId);
  }
}
