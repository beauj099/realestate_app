import 'package:dio/dio.dart';

import 'failures.dart';
import 'network_error_check.dart';

/// Maps exceptions raised in the data layer into user-facing [Failure]s.
Failure mapFailure(Object error) {
  if (error is Failure) return error;
  if (error is DioException) return _mapDioException(error);
  return const UnknownFailure();
}

/// Field-keyed messages from an API `ValidationProblemDetails` response,
/// e.g. `{'email': 'Email address is already registered.'}`, so a screen can
/// show each one under its own input. Keys are camelCase; empty when the
/// response carries none.
Map<String, String> mapFieldErrors(Object error) {
  if (error is! DioException) return const {};
  final data = error.response?.data;
  if (data is! Map) return const {};
  final errors = data['errors'] ?? data['Errors'];
  if (errors is! Map) return const {};
  final result = <String, String>{};
  errors.forEach((key, value) {
    final message = value is List && value.isNotEmpty
        ? value.first.toString()
        : value is String
        ? value
        : null;
    final name = key.toString();
    if (message == null || message.isEmpty || name.isEmpty) return;
    result[name[0].toLowerCase() + name.substring(1)] = message;
  });
  return result;
}

Failure _mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'The server connection is not secure. Please try again.',
      );
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        final detail = _extractServerMessage(error.response?.data);
        if (detail != null) return UnauthorizedFailure(detail);
        return const UnauthorizedFailure();
      }
      if (statusCode == 404) {
        return const ValidationFailure('The requested resource was not found.');
      }
      if (statusCode != null && statusCode >= 500) {
        final serverDetail = _extractServerMessage(error.response?.data);
        if (serverDetail != null) return ServerFailure(serverDetail);
        return const ServerFailure();
      }
      final detail = _extractServerMessage(error.response?.data);
      if (detail != null) return ValidationFailure(detail);
      return const ValidationFailure();
    case DioExceptionType.cancel:
      return const UnknownFailure('The request was cancelled.');
    case DioExceptionType.unknown:
      if (isIoNetworkError(error.error)) {
        return const NetworkFailure();
      }
      return const UnknownFailure();
  }
}

String? _extractServerMessage(dynamic data) {
  if (data == null) return null;
  if (data is String && data.trim().isNotEmpty) {
    final sanitized = _sanitizeMessage(data.trim());
    if (sanitized == null) return null;
    return sanitized;
  }
  if (data is Map) {
    // ASP.NET ProblemDetails: { title, detail, errors: { field: [msg] } }
    // Support case-insensitive keys (Message, Detail, Title, Errors)
    final detail = data['detail'] ?? data['Detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      final sanitized = _sanitizeMessage(detail.trim());
      if (sanitized != null) return sanitized;
    }
    final title = data['title'] ?? data['Title'];
    if (title is String && title.trim().isNotEmpty) {
      final sanitized = _sanitizeMessage(title.trim());
      if (sanitized != null) return sanitized;
    }
    final message = data['message'] ?? data['Message'];
    if (message is String && message.trim().isNotEmpty) {
      final sanitized = _sanitizeMessage(message.trim());
      if (sanitized != null) return sanitized;
    }
    final errors = data['errors'] ?? data['Errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstKey = errors.keys.first;
      final firstVal = errors[firstKey];
      if (firstVal is List && firstVal.isNotEmpty) {
        final msg = firstVal.first.toString();
        if (msg.isNotEmpty) {
          final combined = '$firstKey: $msg';
          return _sanitizeMessage(combined) ?? combined;
        }
      }
      if (firstVal is String && firstVal.isNotEmpty) {
        final combined = '$firstKey: $firstVal';
        return _sanitizeMessage(combined) ?? combined;
      }
    }
  }
  return null;
}

String? _sanitizeMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return null;
  // Filter out HTML responses (e.g. nginx/ASP.NET error pages)
  if (trimmed.contains('<html') ||
      trimmed.contains('<!DOCTYPE') ||
      trimmed.contains('<body')) {
    return null;
  }
  // Filter overly technical stack traces
  if (trimmed.contains(' at ') && trimmed.contains('Exception')) {
    return null;
  }
  // Keep messages short and user-friendly
  if (trimmed.length > 120) {
    return '${trimmed.substring(0, 120).trim()}…';
  }
  return trimmed;
}
