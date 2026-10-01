import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:cng_pump/constants/api_constants.dart';
import 'package:cng_pump/constants/api_endpoints.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/repositories/audit_repository.dart';
import 'package:cng_pump/screens/history/history_screen.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/widgets/history/audit_session_card.dart';
import 'package:cng_pump/widgets/shared_widgets/async_state_view.dart';

Widget _buildTestApp(Widget child, {required HistoryProvider historyProvider}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => PumpProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  setUp(() {
    ApiConstants.setBaseUrl('http://192.168.1.8:5000');
  });

  group('1. History GET API Endpoint & Network Contract Tests', () {
    test('GET /api/v1/capture/history sends correct method, body=none, URL and headers', () async {
      String? capturedUrl;
      String? capturedMethod;
      Map<String, String>? capturedHeaders;
      String? capturedBody;

      final mockHttp = MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedMethod = request.method;
        capturedHeaders = request.headers;
        capturedBody = request.body;

        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'captures': [
              {
                'id': 'mongo_cap_101',
                'captureType': 'nozzle',
                'nozzleNumber': 2,
                'status': 'in_progress',
                'station': {'name': 'Rawalpindi CNG Express'},
                'operator': {'name': 'Asif Mahmood'},
                'startedAt': '2026-09-30T07:40:04.401Z',
                'images': [
                  {
                    'imageType': 'digitalMachine',
                    'imageUrl': 'https://res.cloudinary.com/cng/image/upload/v1/dm_img.png',
                    'captureAt': '2026-09-30T07:40:05.350Z',
                  },
                  {
                    'imageType': 'counter',
                    'imageUrl': 'https://res.cloudinary.com/cng/image/upload/v1/cnt_img.png',
                    'captureAt': '2026-09-30T07:40:06.145Z',
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('jwt_bearer_token_xyz_123');

      final repo = RemoteAuditRepository(client: testApiClient);
      final records = await repo.getHistoryRecords();

      // 1. Verify URL & Method
      expect(capturedMethod, equals('GET'));
      expect(capturedUrl, equals('http://192.168.1.8:5000/api/v1/capture/history'));

      // 2. Verify Body is empty
      expect(capturedBody, isEmpty);

      // 3. Verify Headers
      expect(capturedHeaders?['content-type'], contains('application/json'));
      expect(capturedHeaders?['accept'], contains('application/json'));
      expect(capturedHeaders?['authorization'], equals('Bearer jwt_bearer_token_xyz_123'));

      // 4. Verify Parsed MongoDB Record
      expect(records.length, equals(1));
      final rec = records.first;
      expect(rec.id, equals('mongo_cap_101'));
      expect(rec.stationName, equals('Rawalpindi CNG Express'));
      expect(rec.operatorName, equals('Asif Mahmood'));
      expect(rec.modeName, equals('Nozzle 2'));
      expect(rec.images.length, equals(2));
      expect(rec.images[0].label, equals('Digital Machine'));
      expect(rec.images[0].imageUrl, equals('https://res.cloudinary.com/cng/image/upload/v1/dm_img.png'));
      expect(rec.images[1].label, equals('Counter'));
      expect(rec.images[1].imageUrl, equals('https://res.cloudinary.com/cng/image/upload/v1/cnt_img.png'));
    });

    test('GET request without token does not send Authorization header', () async {
      Map<String, String>? capturedHeaders;

      final mockHttp = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(
          jsonEncode({'success': true, 'captures': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.clearAuthToken();

      final repo = RemoteAuditRepository(client: testApiClient);
      await repo.getHistoryRecords();

      expect(capturedHeaders?['authorization'], isNull);
      expect(capturedHeaders?['content-type'], contains('application/json'));
      expect(capturedHeaders?['accept'], contains('application/json'));
    });
  });

  group('2. HistoryProvider Dynamic State & Parsing Tests', () {
    test('On Status 200: fetches, parses MongoDB records, stores in state and notifies listeners', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 2,
            'captures': [
              {
                'id': 'session_meter_001',
                'captureType': 'meter',
                'status': 'completed',
                'station': 'Islamabad Metro Pump',
                'operator': 'Kamran Akmal',
                'startedAt': '2026-09-30T06:15:00.000Z',
                'images': [
                  {
                    'imageType': 'vb1',
                    'imageUrl': 'https://res.cloudinary.com/cng/vb1.png',
                    'captureAt': '2026-09-30T06:15:10.000Z',
                  },
                  {
                    'imageType': 'vs1',
                    'imageUrl': 'https://res.cloudinary.com/cng/vs1.png',
                    'captureAt': '2026-09-30T06:15:20.000Z',
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      expect(provider.status, equals(AsyncStatus.empty));

      await provider.fetchHistory();

      expect(notifyCount, greaterThanOrEqualTo(2)); // loading + loaded
      expect(provider.status, equals(AsyncStatus.loaded));
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.records.length, equals(1));

      final session = provider.auditSessions.first;
      expect(session.id, equals('session_meter_001'));
      expect(session.modeName, equals('Meter'));
      expect(session.stationName, equals('Islamabad Metro Pump'));
      expect(session.operatorName, equals('Kamran Akmal'));
      expect(session.images[0].label, equals('VB1'));
      expect(session.images[0].imageUrl, equals('https://res.cloudinary.com/cng/vb1.png'));
      expect(session.images[1].label, equals('VS1'));
      expect(session.images[1].imageUrl, equals('https://res.cloudinary.com/cng/vs1.png'));
    });

    test('On Error: catches network failure cleanly and sets error state', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Failed to connect to MongoDB cluster'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      await provider.fetchHistory();

      expect(provider.status, equals(AsyncStatus.error));
      expect(provider.hasError, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Failed to connect to MongoDB cluster'));
    });
  });

  group('3. HistoryScreen (AuditHistoryScreen) UI Lifecycle & State Management Tests', () {
    testWidgets('Loading State: Shows CircularProgressIndicator during fetch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Delayed response to observe loading spinner
      final mockHttp = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 250));
        return http.Response(
          jsonEncode({'success': true, 'captures': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      await tester.pumpWidget(_buildTestApp(
        const AuditHistoryScreen(),
        historyProvider: provider,
      ));

      // After initState postFrameCallback, fetchHistory sets status to loading
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish async delay
      await tester.pumpAndSettle();
    });

    testWidgets('Empty State: Displays clean "No audit history found" UI when list is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'captures': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      await tester.pumpWidget(_buildTestApp(
        const HistoryScreen(),
        historyProvider: provider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('No audit history found'), findsOneWidget);
      expect(find.byType(AuditSessionCard), findsNothing);
    });

    testWidgets('Success State: Renders populated cards dynamically with backend data and images', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'captures': [
              {
                'id': 'cap_dynamic_card',
                'captureType': 'nozzle',
                'nozzleNumber': 1,
                'status': 'in_progress',
                'station': {'name': 'Lahore City Central Station'},
                'operator': {'name': 'Bilal Haider'},
                'startedAt': '2026-09-30T07:40:04.401Z',
                'images': [
                  {
                    'imageType': 'digitalMachine',
                    'imageUrl': 'https://res.cloudinary.com/demo/dm.png',
                    'captureAt': '2026-09-30T07:40:05.350Z',
                  },
                  {
                    'imageType': 'counter',
                    'imageUrl': 'https://res.cloudinary.com/demo/cnt.png',
                    'captureAt': '2026-09-30T07:40:06.145Z',
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      await tester.pumpWidget(_buildTestApp(
        const HistoryScreen(),
        historyProvider: provider,
      ));

      await tester.pumpAndSettle();

      // Card dynamically rendered
      expect(find.byType(AuditSessionCard), findsOneWidget);
      expect(find.text('Lahore City Central Station'), findsOneWidget);
      expect(find.text('Bilal Haider'), findsOneWidget);
      expect(find.text('Nozzle 1'), findsOneWidget);
    });

    testWidgets('Pull-to-Refresh: RefreshIndicator triggers fetchHistory via GET API', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      int callCount = 0;
      final mockHttp = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({'success': true, 'captures': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);
      final provider = HistoryProvider(repository: repo);

      await tester.pumpWidget(_buildTestApp(
        const HistoryScreen(),
        historyProvider: provider,
      ));

      await tester.pumpAndSettle();

      // 1 call from initState
      expect(callCount, equals(1));

      // Pull down to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Second call triggered by RefreshIndicator
      expect(callCount, equals(2));
    });
  });
}
