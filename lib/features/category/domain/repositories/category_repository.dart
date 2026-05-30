import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories(String userId);
  Future<Either<Failure, Unit>> addCategory(CategoryEntity category);
  Future<Either<Failure, Unit>> deleteCategory(String categoryId, String userId);
}