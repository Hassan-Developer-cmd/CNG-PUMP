enum ApiErrorType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  badRequest, // 400
  serverError, // 500+
  networkError, // Socket / DNS / connection refused
  parseError,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType errorType;
  final dynamic responseData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorType = ApiErrorType.unknown,
    this.responseData,
  });

  factory ApiException.fromStatusCode(int statusCode, dynamic responseData) {
    String message = 'An unexpected error occurred ($statusCode)';

    // Extract user-friendly error message from response data if present
    if (responseData is Map) {
      if (responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (responseData['data'] is Map && (responseData['data'] as Map)['message'] != null) {
        message = (responseData['data'] as Map)['message'].toString();
      } else if (responseData['msg'] != null) {
        message = responseData['msg'].toString();
      } else if (responseData['error'] != null) {
        message = responseData['error'].toString();
      } else if (responseData['detail'] != null) {
        message = responseData['detail'].toString();
      } else if (responseData['data'] is Map && (responseData['data'] as Map)['error'] != null) {
        message = (responseData['data'] as Map)['error'].toString();
      }
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      message = responseData.trim();
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message.isEmpty ? 'Bad request. Please check your input.' : message,
          statusCode: 400,
          errorType: ApiErrorType.badRequest,
          responseData: responseData,
        );
      case 401:
        return ApiException(
          message: message.isEmpty ? 'Unauthorized. Invalid credentials or expired session.' : message,
          statusCode: 401,
          errorType: ApiErrorType.unauthorized,
          responseData: responseData,
        );
      case 403:
        return ApiException(
          message: message.isEmpty ? 'Access forbidden. You do not have permission.' : message,
          statusCode: 403,
          errorType: ApiErrorType.forbidden,
          responseData: responseData,
        );
      case 404:
        return ApiException(
          message: message.isEmpty ? 'Resource not found.' : message,
          statusCode: 404,
          errorType: ApiErrorType.notFound,
          responseData: responseData,
        );
      default:
        if (statusCode >= 500) {
          return ApiException(
            message: message.isEmpty ? 'Internal server error. Please try again later.' : message,
            statusCode: statusCode,
            errorType: ApiErrorType.serverError,
            responseData: responseData,
          );
        }
        return ApiException(
          message: message,
          statusCode: statusCode,
          errorType: ApiErrorType.unknown,
          responseData: responseData,
        );
    }
  }

  factory ApiException.networkError([String? customMessage]) {
    return ApiException(
      message: customMessage ?? 'Network connection failed. Please check your internet connection.',
      errorType: ApiErrorType.networkError,
    );
  }

  factory ApiException.timeout([String? customMessage]) {
    return ApiException(
      message: customMessage ?? 'Connection timed out. The server took too long to respond.',
      errorType: ApiErrorType.connectionTimeout,
    );
  }

  @override
  String toString() => message;
}
