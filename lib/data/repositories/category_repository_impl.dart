import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required this.remoteDataSource});

  final CategoryRemoteDataSource remoteDataSource;

  @override
  Future<List<Category>> getCategories() {
    return remoteDataSource.getCategories();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
  }) {
    return remoteDataSource.createCategory(
      name: name,
      icon: icon,
      color: color,
    );
  }

  @override
  Future<Category> updateCategory(Category category) {
    return remoteDataSource.updateCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> deleteCategory(String id) {
    return remoteDataSource.deleteCategory(id);
  }

  @override
  Future<void> seedDefaultCategoriesIfEmpty() {
    return remoteDataSource.seedDefaultCategoriesIfEmpty();
  }
}
