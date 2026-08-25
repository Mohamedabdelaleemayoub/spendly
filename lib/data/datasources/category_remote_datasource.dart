import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory({
    String? id,
    required String name,
    required String icon,
    required String color,
  });
  Future<CategoryModel> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> seedDefaultCategoriesIfEmpty();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await client
          .from(AppConstants.categoriesTable)
          .select()
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<CategoryModel> createCategory({
    String? id,
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final response = await client
          .from(AppConstants.categoriesTable)
          .insert({
            'id': ?id,
            'name': name.trim(),
            'icon': icon,
            'color': color,
          })
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final response = await client
          .from(AppConstants.categoriesTable)
          .update({
            'name': category.name.trim(),
            'icon': category.icon,
            'color': category.color,
          })
          .eq('id', category.id)
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await client
          .from(AppConstants.categoriesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {
    // Handled at database level by SQL migration
  }
}
