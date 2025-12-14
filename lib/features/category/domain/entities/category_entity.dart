import 'package:equatable/equatable.dart';

// Loại danh mục: Chi tiêu hay Thu nhập
enum CategoryType { income, expense }

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String userId;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.userId,
  });

  @override
  List<Object?> get props => [id, name, type, userId];
}