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
    await _getUserCategories(category.userId).add(category.toDocument());
  }

  Future<void> deleteCategory(String categoryId) async {
    // Need userId to get collection reference - categoryId alone is not enough
    // We'll need to find the category first OR pass userId
    // For now, use collectionGroup query to find and delete by id
    final querySnapshot = await _firestore
        .collectionGroup('categories')
        .where(FieldPath.documentId, isEqualTo: categoryId)
        .get();
    
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}