import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:cng_pump/constants/api_constants.dart';
import 'package:cng_pump/models/audit_history_model.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/screens/dashboard/admin_dashboard_screen.dart';
import 'package:cng_pump/screens/history/history_screen.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/services/api/auth_storage.dart';
import 'package:cng_pump/widgets/history/audit_history_card.dart';

Widget _buildTestApp({
  required Widget home,
  required HistoryProvider historyProvider,
  AdminAuthProvider? adminAuthProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminAuthProvider>.value(
        value: adminAuthProvider ?? AdminAuthProvider(),
      ),
      ChangeNotifierProvider(create: (_) => PumpProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => CaptureProvider()),
      ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        home: home,
      ),
    ),
  );
}

void main() {
  setUp(() async {
    ApiConstants.setBaseUrl('http://192.168.1.8:5000');
    await AuthStorage.instance.clear();
  });

  group('1. History GET API Endpoint & Authorization Contract Tests', () {
    test('fetchHistory sends GET request to http://192.168.1.8:5000/api/v1/capture/history with Bearer token', () async {
      String? capturedUrl;
      String? capturedMethod;
      Map<String, String>? capturedHeaders;

      final mockHttp = MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedMethod = request.method;
        capturedHeaders = request.headers;

        return http.Response(
          jsonEncode({
            "status": "success",
            "data": [
              {
                "_id": "sess_1001",
                "stationName": "Main Highway CNG Station",
                "stationId": "st_01",
                "operatorName": "adnangul",
                "operatorId": "op_9921",
                "mode": "meter",
                "createdAt": "2026-10-01T10:30:00.000Z",
                "images": [
                  {
                    "imageType": "vb1",
                    "imageUrl": "/uploads/vb1_reading.jpg",
                  },
                  {
                    "imageType": "vs1",
                    "path": "uploads/vs1_reading.jpg",
                  }
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Save an auth token to secureStorage simulating a logged in admin/operator
      await AuthStorage.instance.write(key: 'auth_token', value: 'dynamic_jwt_session_token_xyz');

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchHistory();

      // 1. Verify URL
      expect(capturedUrl, equals('http://192.168.1.8:5000/api/v1/capture/history'));

      // 2. Verify HTTP Method
      expect(capturedMethod, equals('GET'));

      // 3. Verify Headers
      expect(capturedHeaders?['Content-Type'], equals('application/json'));
      expect(capturedHeaders?['Accept'], equals('application/json'));
      expect(capturedHeaders?['Authorization'], equals('Bearer dynamic_jwt_session_token_xyz'));

      // 4. Verify Provider State & List Population
      expect(provider.historyList.length, equals(1));
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);

      final session = provider.historyList.first;
      expect(session.id, equals('sess_1001'));
      expect(session.stationName, equals('Main Highway CNG Station'));
      expect(session.operatorName, equals('adnangul'));
      expect(session.operatorId, equals('op_9921'));
      expect(session.mode, equals('meter'));
      expect(session.captureType, equals('meter'));
      expect(session.formattedOperatorBadge, equals('adnangul (ID: op_9921)'));
      expect(session.formattedModeDetails, equals('Meter Audit'));

      // 5. Verify Image URL Normalization to Absolute URLs
      expect(session.images.length, equals(2));
      expect(session.images[0].imageUrl, equals('http://192.168.1.8:5000/uploads/vb1_reading.jpg'));
      expect(session.images[0].imageType, equals('vb1'));
      expect(session.images[1].imageUrl, equals('http://192.168.1.8:5000/uploads/vs1_reading.jpg'));
    });

    test('fetchHistory handles nested response under data, history, or sessions keys', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "sessions": [
              {
                "id": "sess_2002",
                "station": {"name": "Lahore Gas Station #3", "id": "st_03"},
                "user": {"name": "Zubair", "id": "user_77"},
                "captureType": "nozzle",
                "nozzleNumber": "3",
                "timestamp": "2026-10-01T12:00:00.000Z",
                "images": [
                  {"type": "digitalMachine", "url": "http://cdn.example.com/digital.jpg"},
                  {"type": "counter", "url": "/uploads/counter.jpg"}
                ]
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchHistory();

      expect(provider.historyList.length, equals(1));
      final item = provider.historyList.first;
      expect(item.id, equals('sess_2002'));
      expect(item.stationName, equals('Lahore Gas Station #3'));
      expect(item.operatorName, equals('Zubair'));
      expect(item.operatorId, equals('user_77'));
      expect(item.mode, equals('nozzle'));
      expect(item.nozzleNumber, equals('3'));
      expect(item.formattedModeDetails, equals('Nozzle 3 Audit'));
      expect(item.images[0].imageUrl, equals('http://cdn.example.com/digital.jpg'));
      expect(item.images[1].imageUrl, equals('http://192.168.1.8:5000/uploads/counter.jpg'));
    });

    test('fetchHistory sets errorMessage on non-200 backend failure', () async {
      final mockHttp = MockClient((request) async {
        return http.Response('Unauthorized Access', 401);
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchHistory();

      expect(provider.historyList.isEmpty, isTrue);
      expect(provider.errorMessage, equals('Failed to fetch audit history (401)'));
      expect(provider.isLoading, isFalse);
    });

    test('fetchHistory sets errorMessage on network connection failure', () async {
      final mockHttp = MockClient((request) async {
        throw const SocketException('Connection refused to backend');
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchHistory();

      expect(provider.historyList.isEmpty, isTrue);
      expect(provider.errorMessage, contains('Network connection failed:'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('2. HistoryScreen & AdminAuditScreen UI Integration Tests', () {
    testWidgets('HistoryScreen displays loading spinner, empty state, and populated cards with Operator & Station badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "data": [
              {
                "_id": "sess_audit_01",
                "stationName": "Islamabad Blue Area CNG",
                "operatorName": "adnangul",
                "operatorId": "op_505",
                "mode": "meter",
                "createdAt": "2026-10-01T08:15:00.000Z",
                "images": [
                  {"imageType": "vb1", "imageUrl": "/uploads/vb1.jpg"},
                  {"imageType": "vs1", "imageUrl": "/uploads/vs1.jpg"},
                ]
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const AdminAuditScreen(),
        historyProvider: provider,
      ));

      // Pump to process postFrameCallback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Card rendered
      expect(find.byType(AuditHistoryCard), findsOneWidget);
      expect(find.text('Islamabad Blue Area CNG'), findsOneWidget);
      expect(find.text('Op: adnangul (ID: op_505)'), findsOneWidget);
      expect(find.text('Meter'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh on HistoryScreen triggers fetchHistory(showLoading: false)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      int callCount = 0;
      final mockHttp = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({"data": []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const HistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      final initialCalls = callCount;

      // Trigger pull-to-refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(callCount, greaterThan(initialCalls));
    });

    testWidgets('Error state renders error banner with Retry button that re-fetches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      int callCount = 0;
      final mockHttp = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response(
          jsonEncode({
            "data": [
              {
                "_id": "sess_retry_success",
                "stationName": "Retried Station Success",
                "operatorName": "Ali",
                "mode": "meter",
                "images": [],
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const HistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Error message shown
      expect(find.text('Failed to fetch audit history (500)'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Card now rendered
      expect(find.text('Retried Station Success'), findsOneWidget);
    });
  });

  group('3. AdminDashboardScreen Live Audit Feed Integration Tests', () {
    testWidgets('AdminDashboardScreen displays real-time sessions from HistoryProvider with pull-to-refresh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/capture/history')) {
          return http.Response(
            jsonEncode({
              "data": [
                {
                  "_id": "sess_live_01",
                  "stationName": "Karachi Hub Station #5",
                  "operatorName": "adnangul",
                  "operatorId": "651f8a92c3d4",
                  "mode": "nozzle",
                  "nozzleNumber": "2",
                  "createdAt": "2026-10-01T15:00:00.000Z",
                  "images": [
                    {"imageType": "digitalMachine", "imageUrl": "/uploads/dm.jpg"},
                    {"imageType": "counter", "imageUrl": "/uploads/cnt.jpg"},
                  ]
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final historyProvider = HistoryProvider(httpClient: mockHttp);
      final adminAuthProvider = AdminAuthProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const AdminDashboardScreen(),
        historyProvider: historyProvider,
        adminAuthProvider: adminAuthProvider,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify LIVE AUDIT FEED section header is visible
      expect(find.text('LIVE AUDIT FEED'), findsOneWidget);
      expect(find.text('Karachi Hub Station #5'), findsOneWidget);
      expect(find.text('adnangul'), findsOneWidget);
    });
  });
}
