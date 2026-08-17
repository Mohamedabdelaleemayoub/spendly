/// Maps raw exceptions to domain [Failure] objects.
///
/// Usage:
/// ```dart
/// try {
///   await dataSource.fetchExpenses();
/// } catch (e) {
///   throw mapExceptionToFailure(e);
/// }
/// ```
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';

/// Converts a caught exception into the appropriate [Failure] subclass.
Failure mapExceptionToFailure(Object exception) {
  debugPrint('🔴 [ExceptionMapper] Caught error: $exception');

  if (exception is AuthException) {
    debugPrint('🔴 [AuthException] Code: ${exception.statusCode}, Message: ${exception.message}');
    return AuthFailure(_authMessage(exception));
  }

  if (exception is PostgrestException) {
    debugPrint(
      '🔴 [PostgrestException] Code: ${exception.code}, '
      'Message: ${exception.message}, '
      'Details: ${exception.details}, '
      'Hint: ${exception.hint}',
    );
    return ServerFailure(_postgrestMessage(exception));
  }

  if (exception is StorageException) {
    debugPrint('🔴 [StorageException] Status: ${exception.statusCode}, Message: ${exception.message}');
    return StorageFailure('خطأ في معالجة المرفقات: ${exception.message}');
  }

  if (exception is SocketException) {
    return const NetworkFailure();
  }

  if (exception is Failure) {
    return exception;
  }

  return UnknownFailure(exception.toString());
}

String _authMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid_credentials')) {
    return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  }
  if (msg.contains('email not confirmed')) {
    return 'يرجى تأكيد بريدك الإلكتروني أولاً لتسجيل الدخول.';
  }
  if (msg.contains('user not found')) {
    return 'لم يتم العثور على المستخدم.';
  }
  if (msg.contains('user already registered') ||
      msg.contains('already registered')) {
    return 'البريد الإلكتروني مسجل مسبقاً.';
  }
  return 'فشل تسجيل الدخول: ${e.message}';
}

String _postgrestMessage(PostgrestException e) {
  final code = e.code?.toUpperCase() ?? '';
  final msg = e.message.toLowerCase();

  if (code == 'PGRST200' || msg.contains('could not find a relationship')) {
    return 'خطأ في علاقات الجداول (PGRST200): يرجى التأكد من تشغيل migration 002 لإنشاء المفتاح الأجنبي.';
  }

  if (code == 'PGRST205' || msg.contains('schema cache') || msg.contains('could not find the table')) {
    return 'تعذر العثور على الجدول في كاش قاعدة البيانات ($code).';
  }

  if (code == '42P01' || msg.contains('relation does not exist')) {
    return 'الجدول غير موجود في قاعدة البيانات ($code).';
  }

  if (code == '42501' || msg.contains('permission denied') || msg.contains('row-level security')) {
    return 'تم رفض العملية بواسطة سياسة الأمان (RLS $code).';
  }

  if (code == '23505' || msg.contains('duplicate key')) {
    return 'هذا السجل موجود بالفعل ($code).';
  }

  if (code == '23503' || msg.contains('foreign key')) {
    return 'تعذر إتمام العملية لوجود بيانات مرتبطة ($code).';
  }

  return 'حدث خطأ أثناء الاتصال بقاعدة البيانات ($code).';
}
