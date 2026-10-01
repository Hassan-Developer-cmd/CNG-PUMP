import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../constants/api_constants.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

/// Centralized HTTP network client for backend communication.
class ApiClient {
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Singleton instance for shared app-wide network access.
  static final ApiClient instance = ApiClient();

  /// Gets the current Bearer Token
  String? get authToken => _authToken;

  /// Whether the client currently holds an authentication token
  bool get isAuthenticated => _authToken != null && _authToken!.trim().isNotEmpty;

  /// Sets or updates the Bearer authorization token
  void setAuthToken(String? token) {
    _authToken = token?.trim().isEmpty == true ? null : token?.trim();
  }

  /// Clears the authorization token on logout
  void clearAuthToken() {
    _authToken = null;
  }

  /// Builds the full Uri from relative endpoint path and optional query parameters
  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConstants.baseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uriString = '$normalizedBase$normalizedPath';
    final parsed = Uri.parse(uriString);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryMap = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return parsed.replace(queryParameters: {
        ...parsed.queryParameters,
        ...queryMap,
      });
    }

    return parsed;
  }

  /// Request interceptor: builds standard JSON headers + Bearer Token
  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...ApiConstants.defaultHeaders,
      if (_authToken != null && _authToken!.isNotEmpty) 'Authorization': 'Bearer $_authToken',
      if (customHeaders != null) ...customHeaders,
    };
    return headers;
  }

  /// Processes HTTP response and transforms errors to [ApiException]
  dynamic _processResponse(http.Response response) {
    dynamic responseData;
    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body);
      }
    } catch (_) {
      responseData = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    throw ApiException.fromStatusCode(response.statusCode, responseData);
  }

  /// Executes an async network call with timeout and network exception mapping
  Future<T> _executeWithSafety<T>(Future<T> Function() networkCall) async {
    try {
      if (_authToken == null || _authToken!.isEmpty) {
        try {
          final savedToken = await AuthStorage.instance.getToken();
          if (savedToken != null && savedToken.trim().isNotEmpty) {
            _authToken = savedToken.trim();
          }
        } catch (_) {}
      }
      return await networkCall().timeout(ApiConstants.connectTimeout);
    } on TimeoutException {
      throw ApiException.timeout(
        'Connection timed out (${ApiConstants.connectTimeout.inSeconds}s). Please verify the server at ${ApiConstants.baseUrl} is reachable.',
      );
    } on SocketException catch (e) {
      throw ApiException.networkError(
        'Unable to connect to server at ${ApiConstants.baseUrl}: ${e.message}. '
        'Please ensure the server is running and your device is on the same network.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network request failed: $e',
        errorType: ApiErrorType.networkError,
      );
    }
  }

  /// HTTP GET
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _httpClient.get(uri, headers: _buildHeaders(headers));
      return _processResponse(response);
    });
  }

  /// HTTP POST
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient.post(
        uri,
        headers: _buildHeaders(headers),
        body: encodedBody,
      );
      return _processResponse(response);
    });
  }

  /// HTTP PUT
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient.put(
        uri,
        headers: _buildHeaders(headers),
        body: encodedBody,
      );
      return _processResponse(response);
    });
  }

  /// HTTP PATCH
  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient.patch(
        uri,
        headers: _buildHeaders(headers),
        body: encodedBody,
      );
      return _processResponse(response);
    });
  }

  /// HTTP DELETE
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint);
      final response = await _httpClient.delete(uri, headers: _buildHeaders(headers));
      return _processResponse(response);
    });
  }

  /// Multipart Form-Data POST: for uploading real-time captured watermarked audit photos
  Future<dynamic> multipartPost(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Map<String, String>? headers,
    MediaType? contentType,
  }) async {
    return _executeWithSafety(() async {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Bearer token & Accept header
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.headers['Accept'] = 'application/json';

      // CRITICAL: Do NOT manually set 'Content-Type': 'application/json' on MultipartRequest.
      // Allow Flutter's HTTP client to automatically generate the multipart boundary header.
      if (headers != null) {
        final filteredHeaders = Map<String, String>.from(headers)
          ..removeWhere((k, _) => k.toLowerCase() == 'content-type');
        request.headers.addAll(filteredHeaders);
      }

      // Add text fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file parts with MediaType
      if (files != null) {
        for (final entry in files.entries) {
          final file = entry.value;
          if (await file.exists()) {
            final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
            final mediaType = contentType ?? MediaType('image', ext);
            final multipartFile = await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: mediaType,
            );
            request.files.add(multipartFile);
          }
        }
      }

      if (request.fields.containsKey('imageType')) {
        String mappedImageType = request.fields['imageType']!;

        if (mappedImageType.toLowerCase().replaceAll(' ', '').contains('micromotion') ||
            mappedImageType.toLowerCase().contains('motion')) {
          mappedImageType = 'microMotion';
        } else if (mappedImageType.toLowerCase().replaceAll(' ', '').contains('digitalmachine') ||
            mappedImageType.toLowerCase().contains('digital')) {
          mappedImageType = 'digitalMachine';
        } else if (mappedImageType.toLowerCase().contains('counter')) {
          mappedImageType = 'counter';
        }

        // Assign the formatted key
        request.fields['imageType'] = mappedImageType;
        debugPrint("Sending imageType: $mappedImageType");
      }

      final streamedResponse =
          await _httpClient.send(request).timeout(ApiConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Upload StatusCode: ${response.statusCode}");
      debugPrint("Upload Body: ${response.body}");

      return _processResponse(response);
    });
  }
}
