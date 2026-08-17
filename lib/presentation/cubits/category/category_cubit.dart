import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/repositories/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit({required this.categoryRepository})
      : super(const CategoryInitial());

  final CategoryRepository categoryRepository;

  @override
  void emit(CategoryState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    emit(const CategoryLoading());
    try {
      _categories = await categoryRepository.getCategories();
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } on Failure catch (e) {
      emit(CategoryError(e.message));
    } catch (e) {
      emit(CategoryError('فشل تحميل الفئات: $e'));
    }
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final newCat = await categoryRepository.createCategory(
        name: name,
        icon: icon,
        color: color,
      );
      _categories = [..._categories, newCat];
      emit(const CategoryActionSuccess('تمت إضافة الفئة بنجاح'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } on Failure catch (e) {
      emit(CategoryError(e.message));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } catch (e) {
      emit(CategoryError('فشل إضافة الفئة: $e'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final updated = await categoryRepository.updateCategory(category);
      _categories = _categories
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      emit(const CategoryActionSuccess('تم تعديل الفئة بنجاح'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } on Failure catch (e) {
      emit(CategoryError(e.message));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } catch (e) {
      emit(CategoryError('فشل تعديل الفئة: $e'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await categoryRepository.deleteCategory(id);
      _categories = _categories.where((c) => c.id != id).toList();
      emit(const CategoryActionSuccess('تم حذف الفئة بنجاح'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } on Failure catch (e) {
      emit(CategoryError(e.message));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    } catch (e) {
      emit(CategoryError('فشل حذف الفئة: $e'));
      emit(CategoryLoaded(List.unmodifiable(_categories)));
    }
  }
}
