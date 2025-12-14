import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.phoneNumber,
    super.role,
    super.isLocked,
    super.hasCompletedWalletOnboarding,
  });

  // Chuyển từ Firebase User sang UserModel (chỉ có thông tin cơ bản)
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      role: 'user', // Mặc định, cần fetch từ Firestore để có role thực
      isLocked: false,
      hasCompletedWalletOnboarding: false,
    );
  }

  // Chuyển từ Firestore Document sang UserModel (có đầy đủ thông tin)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      role: data['role'] ?? 'user',
      isLocked: data['isLocked'] ?? false,
      hasCompletedWalletOnboarding: data['hasCompletedWalletOnboarding'] ?? false,
    );
  }

  // Chuyển thành Map nếu cần lưu xuống Firestore
  Map<String, dynamic> toDocument() {
    return {
      'uid': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role,
      'isLocked': isLocked,
      'hasCompletedWalletOnboarding': hasCompletedWalletOnboarding,
    };
  }
}