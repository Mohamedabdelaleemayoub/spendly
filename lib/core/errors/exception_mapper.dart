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

  if (exception is FunctionException) {
    debugPrint(
      '🔴 [FunctionException] Status: ${exception.status}, '
      'Details: ${exception.details}, '
      'Reason: ${exception.reasonPhrase}',
    );
    return _functionMessage(exception);
  }

  if (exception is SocketException) {
    return const NetworkFailure();
  }

  if (exception is Failure) {
    return exception;
  }

  return UnknownFailure(exception.toString());
}

Failure _functionMessage(FunctionException e) {
  String rawMessage = 'فشلت العملية على الخادم.';
  final details = e.details;

  if (details is Map) {
    if (details['error'] != null) {
      rawMessage = details['error'].toString();
    } else if (details['message'] != null) {
      rawMessage = details['message'].toString();
    }
  } else if (details is String && details.trim().isNotEmpty) {
    rawMessage = details.trim();
  } else if (e.reasonPhrase != null && e.reasonPhrase!.isNotEmpty) {
    rawMessage = e.reasonPhrase!;
  }

  final lower = rawMessage.toLowerCase();
  if (lower.contains('already registered') ||
      lower.contains('already exists') ||
      lower.contains('user already registered') ||
      lower.contains('email already')) {
    return const AuthFailure('البريد الإلكتروني مسجل مسبقاً لمستخدم آخر.');
  }

  if (lower.contains('admin privileges required') ||
      lower.contains('unauthorized') ||
      lower.contains('missing authorization') ||
      lower.contains('invalid authentication session')) {
    return const AuthFailure('غير مصرح لك بإجراء هذه العملية. يلزم صلاحيات المشرف.');
  }

  if (lower.contains('cannot delete your own') ||
      lower.contains('cannot delete self')) {
    return const ServerFailure('لا يمكنك حذف حسابك الحالي.');
  }

  if (lower.contains('cannot delete the last remaining') ||
      (lower.contains('delete') && lower.contains('last remaining administrator'))) {
    return const ServerFailure('لا يمكن حذف آخر مسؤول متبقي في النظام.');
  }

  if (lower.contains('cannot deactivate your own') ||
      lower.contains('cannot deactivate self')) {
    return const ServerFailure('لا يمكنك تعطيل حسابك الحالي.');
  }

  if (lower.contains('cannot deactivate the last active') ||
      lower.contains('last active administrator')) {
    return const ServerFailure('لا يمكن تعطيل آخر مسؤول نشط في النظام.');
  }

  if (lower.contains('cannot demote the last remaining') ||
      (lower.contains('demote') && lower.contains('last remaining administrator'))) {
    return const ServerFailure('لا يمكن تخفيض صلاحية آخر مسؤول متبقي في النظام.');
  }

  if (lower.contains('at least 6 characters')) {
    return const AuthFailure('يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.');
  }

  if (lower.contains('email, password, and full_name are required')) {
    return const ServerFailure('يرجى ملء جميع الحقول المطلوبة (الاسم، البريد الإلكتروني، كلمة المرور).');
  }

  return ServerFailure(rawMessage);
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
