import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/auth/data/models/user_model.dart'; // Để chuyển đổi user

class AccountService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AccountService(this._firebaseAuth, this._firestore);

  // Cập nhật tên hiển thị trong Firebase Auth và Firestore
  Future<UserModel> updateDisplayName(String userId, String newDisplayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.uid != userId) {
      throw Exception('Người dùng không hợp lệ hoặc không được phép');
    }

    // 1. Cập nhật trong Firebase Auth
    await user.updateDisplayName(newDisplayName);

    // 2. Cập nhật trong Firestore
    await _firestore.collection('users').doc(userId).update({
      'displayName': newDisplayName,
    });

    // Trả về UserModel đã cập nhật
    final updatedFirebaseUser = _firebaseAuth.currentUser; // Lấy lại user mới nhất
    return UserModel.fromFirebaseUser(updatedFirebaseUser!);
  }

  // Đổi mật khẩu
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    // Xác thực lại người dùng với mật khẩu cũ
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Mật khẩu hiện tại không đúng');
    }

    // Cập nhật mật khẩu mới
    await user.updatePassword(newPassword);
  }
}