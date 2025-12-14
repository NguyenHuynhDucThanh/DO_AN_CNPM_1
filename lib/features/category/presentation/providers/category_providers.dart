import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/providers/firebase_providers.dart';
import '../../data/services/category_service.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.read(firestoreProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.read(categoryServiceProvider));
});

final getCategoriesUseCaseProvider = Provider((ref) {
  return GetCategoriesUseCase(ref.read(categoryRepositoryProvider));
});

final addCategoryUseCaseProvider = Provider((ref) {
  return AddCategoryUseCase(ref.read(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider((ref) {
  return DeleteCategoryUseCase(ref.read(categoryRepositoryProvider));
});