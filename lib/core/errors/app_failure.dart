import 'package:equatable/equatable.dart';

/// Base failure type.
///
/// All domain-level errors are represented as [Failure] subclasses so that
/// cubits never need to catch raw exceptions — they simply receive a typed
/// failure with a user-friendly [message].
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// User-friendly (Arabic) error description.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// A failure originating from a Supabase / network request.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم. حاول مرة أخرى.']);
}

/// A failure related to authentication.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'فشل تسجيل الدخول. تحقق من بياناتك.']);
}

/// A failure caused by connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.']);
}

/// A failure related to file / storage operations.
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'فشل في رفع أو تحميل الملف.']);
}

/// A generic catch-all failure.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع. حاول مرة أخرى.']);
}
