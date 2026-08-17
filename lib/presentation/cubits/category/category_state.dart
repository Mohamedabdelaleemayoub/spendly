import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories);

  final List<Category> categories;

  @override
  List<Object?> get props => [categories];
}

class CategoryActionSuccess extends CategoryState {
  const CategoryActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
