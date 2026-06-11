import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Connection timed out. Please check your internet.');
      case DioExceptionType.connectionError:
        return const ApiException('Cannot connect to server. Is the backend running?');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final detail = e.response?.data?['detail'] ?? 'Something went wrong.';
        return ApiException(detail.toString(), statusCode: code);
      default:
        return ApiException(e.message ?? 'Unknown error occurred.');
    }
  }

  @override
  String toString() => 'ApiException: \$message (code: \$statusCode)';
}
