import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber; // New field
  final String role; // "admin" hoặc "user"
  final bool isLocked; // true nếu tài khoản bị khóa

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.role = 'user', // Mặc định là user
    this.isLocked = false, // Mặc định không bị khóa
  });

  @override
  List<Object?> get props => [id, email, displayName, phoneNumber, role, isLocked];
  
  // Helper method để check xem có phải admin không
  bool get isAdmin => role == 'admin';
}