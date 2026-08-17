import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
  });
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> seedDefaultCategoriesIfEmpty();
}
