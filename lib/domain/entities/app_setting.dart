import 'package:equatable/equatable.dart';

class AppSetting extends Equatable {
  const AppSetting({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
    this.updatedBy,
  });

  final String key;
  final Map<String, dynamic> value;
  final String? description;
  final DateTime? updatedAt;
  final String? updatedBy;

  bool get boolValue => value['enabled'] == true;

  @override
  List<Object?> get props => [key, value, description, updatedAt, updatedBy];
}
