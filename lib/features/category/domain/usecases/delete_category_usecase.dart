import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository repository;

  DeleteCategoryUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String categoryId, String userId) {
    return repository.deleteCategory(categoryId, userId);
  }
}
