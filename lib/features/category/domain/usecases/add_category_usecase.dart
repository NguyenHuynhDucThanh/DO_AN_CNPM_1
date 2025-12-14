import 'package:dartz/dartz.dart';
import 'package:finance_app/core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class AddCategoryUseCase {
  final CategoryRepository repository;
  AddCategoryUseCase(this.repository);

  Future<Either<Failure, Unit>> call(CategoryEntity category) {
    return repository.addCategory(category);
  }
}