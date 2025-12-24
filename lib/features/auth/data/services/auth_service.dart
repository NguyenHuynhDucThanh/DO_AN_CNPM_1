import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth, this._firestore);

  // Login và lấy thông tin đầy đủ từ Firestore
  Future<UserModel> login(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = userCredential.user!;
    
    // Lấy thông tin từ Firestore để có role và isLocked
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      // Nếu document chưa tồn tại, tạo mới với role mặc định
      final newUserModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: 'user',
        isLocked: false
      );
      await _firestore.collection('users').doc(user.uid).set(newUserModel.toDocument());
      return newUserModel;
    }
    
    final userModel = UserModel.fromFirestore(userDoc);
    
    // Kiểm tra xem tài khoản có bị khóa không
    if (userModel.isLocked) {
      await _firebaseAuth.signOut();
      throw Exception('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ admin.');
    }
    
    return userModel;
  }

  // Register và tạo user document trong Firestore
  Future<UserModel> register(String email, String password, {String? displayName, String? phoneNumber}) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = userCredential.user!;
    
    // Tạo user document trong Firestore với role mặc định là 'user'
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: 'user',
      isLocked: false
    );
    
    //Lưu hồ sơ trong Firestore
    await _firestore.collection('users').doc(user.uid).set({
      ...userModel.toDocument(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return userModel;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  // Lấy UserModel đầy đủ từ Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;
    
    return UserModel.fromFirestore(userDoc);
  }
}

