import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore;

  CategoryService(this._firestore);

  CollectionReference _getUserCategories(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  Future<List<CategoryModel>> getCategories(String userId) async {
    final snapshot = await _getUserCategories(userId).get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final col = _getUserCategories(category.userId);
    final existing = await getCategories(category.userId);
    final duplicate = existing.any(
      (e) => e.name == category.name && e.type == category.type,
    );
    if (duplicate) return;

    await col.doc(category.id).set(category.toDocument());
  }

  // ĐÃ SỬA: Truyền thêm userId vào và xóa trực tiếp bằng đường dẫn chuẩn
  Future<void> deleteCategory(String categoryId, String userId) async {
    await _getUserCategories(userId).doc(categoryId).delete();
  }
}