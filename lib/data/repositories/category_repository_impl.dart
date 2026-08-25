import 'package:flutter/foundation.dart' hide Category;
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../datasources/local_database.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final CategoryRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final remote = await remoteDataSource.getCategories();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveCategories(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [CategoryRepositoryImpl] Remote getCategories failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        final localList = await localDatabase!.getCategories();
        if (localList.isNotEmpty) return localList;
      }
      return _getDefaultCategories();
    }
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    final clientCatId = UuidGenerator.generate();
    final now = DateTime.now();

    final localModel = CategoryModel(
      id: clientCatId,
      name: name,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveCategory(localModel);
    }

    try {
      final remote = await remoteDataSource.createCategory(
        id: clientCatId,
        name: name,
        icon: icon,
        color: color,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveCategory(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [CategoryRepositoryImpl] Remote createCategory failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'category',
          entityId: clientCatId,
          operation: 'INSERT',
          payload: {
            'id': clientCatId,
            'name': name.trim(),
            'icon': icon,
            'color': color,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveCategory(model);
    }

    try {
      final remote = await remoteDataSource.updateCategory(model);
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveCategory(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [CategoryRepositoryImpl] Remote updateCategory failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'category',
          entityId: category.id,
          operation: 'UPDATE',
          payload: {
            'id': category.id,
            'name': category.name.trim(),
            'icon': category.icon,
            'color': category.color,
          },
        );
      }
      return model;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.deleteCategory(id);
    }

    try {
      await remoteDataSource.deleteCategory(id);
    } catch (e) {
      debugPrint('⚠️ [CategoryRepositoryImpl] Remote deleteCategory failed ($e), enqueued in sync queue.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'category',
          entityId: id,
          operation: 'DELETE',
          payload: {'id': id},
        );
      }
    }
  }

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      final existing = await localDatabase!.getCategories();
      if (existing.isEmpty) {
        await localDatabase!.saveCategories(_getDefaultCategories());
      }
    }
  }

  List<CategoryModel> _getDefaultCategories() {
    final now = DateTime.now();
    return [
      CategoryModel(id: 'cat_food', name: 'طعام ومشروبات', icon: 'restaurant', color: '#FF7675', createdAt: now, updatedAt: now),
      CategoryModel(id: 'cat_transport', name: 'مواصلات وانتقالات', icon: 'directions_car', color: '#74B9FF', createdAt: now, updatedAt: now),
      CategoryModel(id: 'cat_hotel', name: 'إقامة وفنادق', icon: 'hotel', color: '#A29BFE', createdAt: now, updatedAt: now),
      CategoryModel(id: 'cat_supplies', name: 'مستلزمات ومشتريات', icon: 'shopping_bag', color: '#55EFC4', createdAt: now, updatedAt: now),
      CategoryModel(id: 'cat_bills', name: 'فواتير وخدمات', icon: 'receipt', color: '#FFEAA7', createdAt: now, updatedAt: now),
      CategoryModel(id: 'cat_other', name: 'أخرى ومتنوعة', icon: 'more_horiz', color: '#636E72', createdAt: now, updatedAt: now),
    ];
  }
}
