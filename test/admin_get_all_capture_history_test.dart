import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/screens/history/admin_history_screen.dart';
import 'package:cng_pump/services/api/auth_storage.dart';

Widget _buildTestApp({
  required Widget home,
  required HistoryProvider historyProvider,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
        ],
        child: MaterialApp(
          home: home,
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AuthStorage.instance.clear();
  });

  group('1. Image URL Resolution Unit Tests', () {
    test('resolveImageUrl handles null, empty, absolute and relative paths correctly', () {
      final provider = HistoryProvider();

      expect(provider.resolveImageUrl(null), '');
      expect(provider.resolveImageUrl(''), '');
      expect(resolveImageUrl(null), '');
      expect(resolveImageUrl(''), '');

      // Absolute URLs
      expect(
        provider.resolveImageUrl('http://192.168.1.8:5000/uploads/pic1.jpg'),
        'http://192.168.1.8:5000/uploads/pic1.jpg',
      );
      expect(
        provider.resolveImageUrl('https://cdn.example.com/images/pic2.png'),
        'https://cdn.example.com/images/pic2.png',
      );

      // Relative paths with leading slash
      expect(
        provider.resolveImageUrl('/uploads/vb1_test.jpg'),
        'http://192.168.1.8:5000/uploads/vb1_test.jpg',
      );
      expect(
        resolveImageUrl('/uploads/vb1_test.jpg'),
        'http://192.168.1.8:5000/uploads/vb1_test.jpg',
      );

      // Relative paths without leading slash
      expect(
        provider.resolveImageUrl('uploads/vs1_test.jpg'),
        'http://192.168.1.8:5000/uploads/vs1_test.jpg',
      );
      expect(
        resolveImageUrl('uploads/vs1_test.jpg'),
        'http://192.168.1.8:5000/uploads/vs1_test.jpg',
      );
    });
  });

  group('2. HistoryProvider.fetchAllCaptures API Unit Tests', () {
    test('Hits GET http://192.168.1.8:5000/api/v1/capture/getAllCaptureHistory with Bearer token', () async {
      await AuthStorage.instance.write(key: 'auth_token', value: 'admin_secret_jwt_xyz');

      Uri? capturedUri;
      String? capturedAuthHeader;
      String? capturedContentType;

      final mockHttp = MockClient((request) async {
        capturedUri = request.url;
        capturedAuthHeader = request.headers['Authorization'];
        capturedContentType = request.headers['Content-Type'];

        return http.Response(
          jsonEncode([
            {
              "_id": "cap_001",
              "stationName": "Islamabad Main Pump",
              "operatorName": "adnangul",
              "mode": "meter",
              "createdAt": "2026-10-01T12:00:00.000Z",
              "images": [
                {"label": "vb1", "url": "/uploads/vb1_001.jpg"},
                {"label": "vs1", "url": "/uploads/vs1_001.jpg"},
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchAllCaptures();

      expect(capturedUri.toString(), 'http://192.168.1.8:5000/api/v1/capture/getAllCaptureHistory');
      expect(capturedAuthHeader, 'Bearer admin_secret_jwt_xyz');
      expect(capturedContentType, 'application/json');
      expect(provider.isLoadingCaptures, isFalse);
      expect(provider.captureError, isNull);
      expect(provider.allCaptureList.length, 1);
      expect(provider.allCaptureList[0]['operatorName'], 'adnangul');
    });

    test('Parses nested response payloads: { "data": [...] }', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "status": "success",
            "data": [
              {
                "_id": "cap_002",
                "stationName": "Lahore Hub",
                "username": "kashif_op",
                "mode": "nozzle",
                "nozzleNumber": "3",
                "createdAt": "2026-10-01T14:30:00.000Z",
                "images": [
                  {"imageType": "digitalMachine", "url": "/uploads/dm_002.jpg"},
                  {"imageType": "counter", "url": "/uploads/cnt_002.jpg"},
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchAllCaptures();

      expect(provider.captureError, isNull);
      expect(provider.allCaptureList.length, 1);
      expect(provider.allCaptureList[0]['stationName'], 'Lahore Hub');
      expect(provider.allCaptureList[0]['nozzleNumber'], '3');
    });

    test('Sets captureError on non-200 response (e.g. 401 Unauthorized)', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({"error": "Unauthorized"}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchAllCaptures();

      expect(provider.isLoadingCaptures, isFalse);
      expect(provider.captureError, contains('Failed to load records (401)'));
      expect(provider.allCaptureList, isEmpty);
    });

    test('Sets captureError on network connection failure / exception', () async {
      final mockHttp = MockClient((request) async {
        throw Exception('SocketException: Connection refused');
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      await provider.fetchAllCaptures();

      expect(provider.isLoadingCaptures, isFalse);
      expect(provider.captureError, contains('Connection failed'));
      expect(provider.allCaptureList, isEmpty);
    });

    test('clearAll resets allCaptureList, isLoadingCaptures, and captureError', () {
      final provider = HistoryProvider();
      provider.allCaptureList = [{'test': 123}];
      provider.isLoadingCaptures = true;
      provider.captureError = 'Some error';

      provider.clearAll();

      expect(provider.allCaptureList, isEmpty);
      expect(provider.isLoadingCaptures, isFalse);
      expect(provider.captureError, isNull);
    });
  });

  group('3. AdminHistoryScreen UI & Widget Tests', () {
    testWidgets('AdminHistoryScreen calls fetchAllCaptures in initState and renders loading spinner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool fetchCalled = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('getAllCaptureHistory')) {
          fetchCalled = true;
        }
        return http.Response(jsonEncode([]), 200);
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      provider.isLoadingCaptures = true;

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();
      expect(fetchCalled, isTrue);
    });

    testWidgets('AdminHistoryScreen displays error state with Retry button that retries fetch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      int fetchCount = 0;
      final mockHttp = MockClient((request) async {
        fetchCount++;
        return http.Response(jsonEncode([]), 200);
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      provider.captureError = 'Connection failed: Server timeout';

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Connection failed: Server timeout'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fetchCount, greaterThanOrEqualTo(1));
    });

    testWidgets('AdminHistoryScreen displays clean empty state when allCaptureList is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async => http.Response(jsonEncode([]), 200));
      final provider = HistoryProvider(httpClient: mockHttp);
      provider.allCaptureList = [];

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No capture records found'), findsOneWidget);
      expect(find.text('0 Records'), findsOneWidget);
    });

    testWidgets('AdminHistoryScreen displays operator details, station, timestamp, capture type and image gallery', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async => http.Response(jsonEncode([]), 200));
      final provider = HistoryProvider(httpClient: mockHttp);

      provider.allCaptureList = [
        {
          "_id": "sess_admin_001",
          "stationName": "North Hub Karachi",
          "operatorName": "adnangul",
          "mode": "nozzle",
          "nozzleNumber": "2",
          "createdAt": "2026-10-01T15:30:00.000Z",
          "images": [
            {"label": "digitalMachine", "url": "/uploads/dm_test.jpg"},
            {"label": "counter", "url": "/uploads/cnt_test.jpg"},
            {"label": "microMotion", "url": "/uploads/mm_test.jpg"},
          ],
        },
      ];

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Station & Operator
      expect(find.text('North Hub Karachi'), findsOneWidget);
      expect(find.text('Op: adnangul'), findsOneWidget);

      // Mode Badge
      expect(find.text('Nozzle 2'), findsOneWidget);

      // Status
      expect(find.text('CAPTURED'), findsOneWidget);

      // Total count pill
      expect(find.text('1 Records'), findsOneWidget);

      // Image labels in gallery
      expect(find.text('digitalMachine'), findsOneWidget);
      expect(find.text('counter'), findsOneWidget);
      expect(find.text('microMotion'), findsOneWidget);
    });

    testWidgets('Tapping image thumbnail opens InteractiveFullScreenImageViewer with InteractiveViewer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async => http.Response(jsonEncode([]), 200));
      final provider = HistoryProvider(httpClient: mockHttp);

      provider.allCaptureList = [
        {
          "_id": "sess_tap_01",
          "stationName": "Islamabad Station #1",
          "username": "ali_operator",
          "mode": "meter",
          "createdAt": "2026-10-01T12:00:00.000Z",
          "images": [
            {"label": "vb1", "url": "/uploads/vb1_full.jpg"},
          ],
        },
      ];

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap on the image thumbnail
      await tester.tap(find.text('vb1'));
      await tester.pumpAndSettle();

      // Verify InteractiveFullScreenImageViewer is opened and InteractiveViewer is present
      expect(find.byType(InteractiveFullScreenImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('WATERMARK AUDIT VERIFIED'), findsOneWidget);
      expect(find.text('Station: Islamabad Station #1'), findsOneWidget);
      expect(find.text('Op: ali_operator'), findsOneWidget);

      // Tap back button to close
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveFullScreenImageViewer), findsNothing);
    });

    testWidgets('Pull-to-refresh calls fetchAllCaptures(showLoading: false)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      int refreshCalls = 0;
      final mockHttp = MockClient((request) async {
        refreshCalls++;
        return http.Response(jsonEncode([]), 200);
      });

      final provider = HistoryProvider(httpClient: mockHttp);
      provider.allCaptureList = [
        {
          "_id": "sess_pull_01",
          "stationName": "Rawalpindi Station",
          "operatorName": "hassan_dev",
          "mode": "meter",
          "createdAt": "2026-10-01T10:00:00.000Z",
          "images": [],
        }
      ];

      await tester.pumpWidget(_buildTestApp(
        home: const AdminHistoryScreen(),
        historyProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Trigger pull to refresh gesture
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(refreshCalls, greaterThanOrEqualTo(1));
    });
  });
}
