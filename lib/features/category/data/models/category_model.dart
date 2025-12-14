import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    required super.userId,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'type': type == CategoryType.income ? 'income' : 'expense',
      'userId': userId,
    };
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      userId: entity.userId,
    );
  }
}