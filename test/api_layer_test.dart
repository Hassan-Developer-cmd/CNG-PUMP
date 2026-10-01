import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cng_pump/constants/api_endpoints.dart';
import 'package:cng_pump/models/admin_profile_model.dart';
import 'package:cng_pump/models/audit_config_model.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/capture_upload_result.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/models/pump_station_model.dart';
import 'package:cng_pump/models/station_history_item.dart';
import 'package:cng_pump/models/comparison_history_record.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/repositories/audit_repository.dart';
import 'package:cng_pump/repositories/auth_repository.dart';
import 'package:cng_pump/repositories/pump_repository.dart';
import 'package:cng_pump/repositories/user_repository.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/services/api/api_exception.dart';
import 'package:cng_pump/widgets/shared_widgets/async_state_view.dart';

void main() {
  group('1. ApiClient & Network Service Layer Tests', () {
    test('Bearer Token handling and headers injection', () async {
      String? recordedAuthHeader;

      final mockHttp = MockClient((request) async {
        recordedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = ApiClient(httpClient: mockHttp);

      // 1. Initial state: not authenticated
      expect(client.isAuthenticated, isFalse);
      expect(client.authToken, isNull);

      await client.get('/test');
      expect(recordedAuthHeader, isNull);

      // 2. Set token
      client.setAuthToken('my_jwt_token_123');
      expect(client.isAuthenticated, isTrue);
      expect(client.authToken, equals('my_jwt_token_123'));

      await client.get('/test');
      expect(recordedAuthHeader, equals('Bearer my_jwt_token_123'));

      // 3. Clear token
      client.clearAuthToken();
      expect(client.isAuthenticated, isFalse);
      expect(client.authToken, isNull);

      await client.get('/test');
      expect(recordedAuthHeader, isNull);
    });

    test('Standardized error handling: 401 Unauthorized', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Invalid session or credentials.'}),
          401,
        );
      });

      final client = ApiClient(httpClient: mockHttp);

      expect(
        () => client.get('/protected'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        ).having(
          (e) => e.errorType,
          'errorType',
          ApiErrorType.unauthorized,
        )),
      );
    });

    test('Standardized error handling: 500 Server Error', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Internal database failure'}),
          500,
        );
      });

      final client = ApiClient(httpClient: mockHttp);

      expect(
        () => client.post('/items', body: {'name': 'Test'}),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        ).having(
          (e) => e.errorType,
          'errorType',
          ApiErrorType.serverError,
        )),
      );
    });

    test('Multipart form upload sends fields and headers', () async {
      String? capturedAuth;

      final mockHttp = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response(jsonEncode({'success': true, 'id': 'aud_999'}), 201);
      });

      final client = ApiClient(httpClient: mockHttp);
      client.setAuthToken('token_abc');

      final result = await client.multipartPost(
        ApiEndpoints.audits,
        fields: {'stationName': 'Hub 1', 'operatorName': 'Ali'},
      );

      expect(result, isA<Map>());
      expect(result['success'], isTrue);
      expect(capturedAuth, equals('Bearer token_abc'));
    });
  });

  group('2. Model Serialization (fromJson / toJson) Tests', () {
    test('PumpStation serializes and deserializes robustly', () {
      final json = {
        'id': 'ps_101',
        'name': 'Peshawar Station',
        'location': 'Ring Road',
        'totalPumps': 8,
        'status': 'active',
        'assignedUserIds': ['u1', 'u2'],
        'categories': ['Fuel Pump', 'Meter'],
        'notes': 'High pressure pump unit',
        'createdAt': '2026-09-29T10:00:00.000Z',
      };

      final model = PumpStation.fromJson(json);
      expect(model.id, equals('ps_101'));
      expect(model.name, equals('Peshawar Station'));
      expect(model.totalPumps, equals(8));
      expect(model.isActive, isTrue);

      final encoded = model.toJson();
      expect(encoded['id'], equals('ps_101'));
      expect(encoded['totalPumps'], equals(8));
      expect(encoded['status'], equals('active'));
    });

    test('CngUser serializes and deserializes with UserRole', () {
      final json = {
        'id': 'op_7890',
        'name': 'Hamza Ali',
        'email': 'hamza@cnghub.com',
        'phone': '+923001234567',
        'role': 'operator',
        'assignedStation': 'Main CNG',
        'isActive': true,
        'createdAt': '2026-09-29T08:00:00.000Z',
      };

      final user = CngUser.fromJson(json);
      expect(user.id, equals('op_7890'));
      expect(user.role, equals(UserRole.operator));

      final back = user.toJson();
      expect(back['id'], equals('op_7890'));
      expect(back['role'], equals('operator'));
    });

    test('CaptureHistoryItem serializes and handles null safety', () {
      final emptyJson = <String, dynamic>{};
      final item = CaptureHistoryItem.fromJson(emptyJson);

      expect(item.id, isNotEmpty);
      expect(item.stationName, equals(''));
      expect(item.operatorName, equals(''));
      expect(item.images, isEmpty);

      final encoded = item.toJson();
      expect(encoded.containsKey('dateTime'), isTrue);
      expect(encoded['images'], isEmpty);
    });

    test('AdminProfile handles dynamic json without mock fallbacks', () {
      final json = {
        'name': 'Custom Admin',
        'username': 'admin_ops',
        'email': 'ops@cnghub.com',
        'notificationsEnabled': false,
      };

      final profile = AdminProfile.fromJson(json);
      expect(profile.name, equals('Custom Admin'));
      expect(profile.username, equals('admin_ops'));
      expect(profile.email, equals('ops@cnghub.com'));
      expect(profile.notificationsEnabled, isFalse);
    });
  });

  group('3. Providers Decoupled API Integration & State Tests', () {
    test('PumpProvider starts empty and updates AsyncStatus on fetch', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'p1',
              'name': 'Dynamic Station 1',
              'location': 'Lahore',
              'totalPumps': 4,
              'status': 'active',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemotePumpRepository(client: apiClient);
      final provider = PumpProvider(repository: repo);

      // 1. Initial State: Must be completely empty with no hardcoded items!
      expect(provider.allStations, isEmpty);
      expect(provider.totalPumps, equals(0));
      expect(provider.status, equals(AsyncStatus.empty));

      // 2. Fetch from API
      await provider.fetchStations();

      expect(provider.allStations.length, equals(1));
      expect(provider.totalPumps, equals(4));
      expect(provider.allStations.first.name, equals('Dynamic Station 1'));
      expect(provider.status, equals(AsyncStatus.loaded));
    });

    test('UserProvider starts empty and loads dynamic operators', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'op_1',
              'name': 'Zaid Tariq',
              'email': 'zaid@cnghub.com',
              'role': 'operator',
              'assignedStation': 'Station A',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteUserRepository(client: apiClient);
      final provider = UserProvider(repository: repo);

      expect(provider.allUsers, isEmpty);
      expect(provider.status, equals(AsyncStatus.empty));

      await provider.fetchUsers();

      expect(provider.allUsers.length, equals(1));
      expect(provider.allUsers.first.name, equals('Zaid Tariq'));
      expect(provider.status, equals(AsyncStatus.loaded));
    });

    test('HistoryProvider starts empty and fetches audit feeds', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'aud_101',
              'stationName': 'Station Alpha',
              'operatorName': 'Operator 1',
              'dateTime': DateTime.now().toIso8601String(),
              'images': [],
              'hasCorruption': false,
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: apiClient);
      final provider = HistoryProvider(repository: repo);

      expect(provider.records, isEmpty);
      expect(provider.status, equals(AsyncStatus.empty));

      await provider.fetchHistory();

      expect(provider.records.length, equals(1));
      expect(provider.records.first.stationName, equals('Station Alpha'));
      expect(provider.status, equals(AsyncStatus.loaded));
    });

    test('AdminAuthProvider dynamic remote login sets token', () async {
      final mockHttp = MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        if (body['email'] == 'super@cnghub.com' && body['password'] == 'Secret123!') {
          return http.Response(
            jsonEncode({
              'token': 'jwt_super_admin_secure',
              'user': {
                'name': 'Super Admin',
                'username': 'admin_super',
                'email': 'super@cnghub.com',
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'message': 'Invalid credentials'}), 401);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuthRepository(client: apiClient);
      final authProvider = AdminAuthProvider(repository: repo, client: apiClient);

      expect(authProvider.isLoggedIn, isFalse);

      final ok = await authProvider.login('super@cnghub.com', 'Secret123!');
      expect(ok, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.profile.name, equals('Super Admin'));
      expect(apiClient.authToken, equals('jwt_super_admin_secure'));

      // Logout clears token
      await authProvider.logout();
      expect(authProvider.isLoggedIn, isFalse);
      expect(apiClient.authToken, isNull);
    });

    test('CaptureProvider submitAuditSession triggers repository multipart save', () async {
      bool saveCalled = false;
      final mockRepo = _TestAuditRepository(
        onSave: (record) async {
          saveCalled = true;
        },
      );

      final captureProvider = CaptureProvider(repository: mockRepo);
      expect(captureProvider.isSubmitting, isFalse);

      final session = await captureProvider.submitAuditSession(
        stationName: 'Test Pump Hub',
        operatorName: 'Ali Khan',
      );

      expect(saveCalled, isTrue);
      expect(session.stationName, equals('Test Pump Hub'));
      expect(session.operatorName, equals('Ali Khan'));
      expect(captureProvider.isSubmitting, isFalse);
    });
  });
}

class _TestAuditRepository implements AuditRepository {
  final Future<void> Function(CaptureHistoryItem record) onSave;

  _TestAuditRepository({required this.onSave});

  @override
  AuditConfigModel get initialAuditConfig => const AuditConfigModel();

  @override
  List<ComparisonHistoryRecord> get initialComparisonRecords => const [];

  @override
  List<StationHistoryItem> get initialStationRecords => const [];

  @override
  Future<AuditConfigModel> getAuditConfig() async => const AuditConfigModel();

  @override
  Future<List<ComparisonHistoryRecord>> getComparisonRecords() async => const [];

  @override
  Future<List<CaptureHistoryItem>> getHistoryRecords() async => const [];

  @override
  Future<List<StationHistoryItem>> getStationRecords() async => const [];

  @override
  Future<void> saveHistoryRecord(CaptureHistoryItem record) => onSave(record);

  @override
  Future<CaptureUploadResult> uploadCapturedImage({
    required String mode,
    required String readingType,
    String? imageType,
    required File imageFile,
    String? readingValue,
    DateTime? timestamp,
  }) async {
    return const CaptureUploadResult(success: true);
  }

  @override
  Future<Map<String, dynamic>> completeAuditSession({
    required String sessionId,
    String? mode,
    List<CapturedImage>? capturedImages,
    File? imageFile,
    String? imageType,
    List<String>? imageIds,
    List<String>? imageUrls,
    String? statusText,
    bool hasCorruption = false,
    String? difference,
    String? threshold,
    String? stationName,
    String? operatorName,
  }) async {
    return {'success': true, 'sessionId': sessionId};
  }
}
