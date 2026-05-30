import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryService service;

  CategoryRepositoryImpl(this.service);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories(String userId) async {
    try {
      final models = await service.getCategories(userId);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addCategory(CategoryEntity category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      await service.addCategory(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // --- CHỖ ĐÃ SỬA: Thêm 'String userId' vào tham số và truyền xuống service ---
  @override
  Future<Either<Failure, Unit>> deleteCategory(String categoryId, String userId) async {
    try {
      await service.deleteCategory(categoryId, userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}