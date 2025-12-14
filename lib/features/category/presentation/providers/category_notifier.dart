import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import 'category_providers.dart';

abstract class CategoryState {}
class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  CategoryLoaded(this.categories);
}
class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final GetCategoriesUseCase _getUseCase;
  final AddCategoryUseCase _addUseCase;
  final DeleteCategoryUseCase _deleteUseCase;

  CategoryNotifier(this._getUseCase, this._addUseCase, this._deleteUseCase) : super(CategoryInitial());

  Future<void> fetchCategories(String userId) async {
    state = CategoryLoading();
    final result = await _getUseCase(userId);
    result.fold(
      (failure) => state = CategoryError(failure.message),
      (list) => state = CategoryLoaded(list),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    // Lưu lại list cũ để cập nhật optimistic hoặc reload sau
    final result = await _addUseCase(category);
    result.fold(
      (failure) => state = CategoryError(failure.message),
      (_) => fetchCategories(category.userId), // Reload lại list
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final result = await _deleteUseCase(categoryId);
    result.fold(
      (failure) => state = CategoryError(failure.message),
      (_) {
        // Reload categories - need userId from current state
        if (state is CategoryLoaded) {
          final currentCategories = (state as CategoryLoaded).categories;
          if (currentCategories.isNotEmpty) {
            fetchCategories(currentCategories.first.userId);
          }
        }
      },
    );
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(
    ref.read(getCategoriesUseCaseProvider),
    ref.read(addCategoryUseCaseProvider),
    ref.read(deleteCategoryUseCaseProvider),
  );
});