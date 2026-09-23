import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/errors/failure_mapper.dart';

DioException _badRequest(Object? body) {
  final options = RequestOptions(path: '/api/auth/reset-password');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 400, data: body),
  );
}

void main() {
  test('maps ValidationProblemDetails errors to camelCase field keys', () {
    final errors = mapFieldErrors(
      _badRequest({
        'title': 'Validation failed',
        'errors': {
          'code': ['Invalid or expired code.'],
          'NewPassword': ['Password must be at least 6 characters.'],
        },
      }),
    );
    expect(errors, {
      'code': 'Invalid or expired code.',
      'newPassword': 'Password must be at least 6 characters.',
    });
  });

  test('is empty when the response carries no field errors', () {
    expect(mapFieldErrors(_badRequest({'detail': 'Nope'})), isEmpty);
    expect(mapFieldErrors(_badRequest('plain text')), isEmpty);
    expect(mapFieldErrors(Exception('not dio')), isEmpty);
  });
}
