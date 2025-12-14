import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<CategoryEntity>>> call(String userId) {
    return repository.getCategories(userId);
  }
}