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

  /// [showLoading] = false khi refresh sau add/delete: giữ danh sách cũ hiển thị
  /// thay vì thay bằng spinner xoay vô hạn. Spinner vô hạn khiến
  /// `pumpAndSettle` trong integration test bị treo (không bao giờ settle).
  Future<void> fetchCategories(String userId, {bool showLoading = true}) async {
    if (showLoading) state = CategoryLoading();
    final result = await _getUseCase(userId);
    result.fold(
      (failure) => state = CategoryError(failure.message),
      (list) => state = CategoryLoaded(list),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    final result = await _addUseCase(category);
    await result.fold<Future<void>>(
      (failure) async {
        state = CategoryError(failure.message);
      },
      (_) async {
        await fetchCategories(category.userId, showLoading: false);
      },
    );
  }

  // --- ĐÃ SỬA: Thêm userId vào tham số ---
  Future<void> deleteCategory(String categoryId, String userId) async {
    // Gọi UseCase truyền đủ 2 tham số
    final result = await _deleteUseCase(categoryId, userId);

    result.fold(
      (failure) => state = CategoryError(failure.message),
      (_) async {
        // Tải lại danh sách (giữ list cũ, không bật spinner vô hạn)
        await fetchCategories(userId, showLoading: false);
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
