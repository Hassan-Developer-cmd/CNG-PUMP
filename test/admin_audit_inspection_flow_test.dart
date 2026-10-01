import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cng_pump/config/app_dependencies.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/station_history_item.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/screens/dashboard/admin_dashboard_screen.dart';
import 'package:cng_pump/screens/history/admin_audit_detail_screen.dart';
import 'package:cng_pump/screens/history/audit_photo_fullscreen_viewer.dart';
import 'package:cng_pump/screens/history/history_screen.dart';
import 'package:cng_pump/widgets/history/audit_session_card.dart';
import 'package:cng_pump/widgets/history/watermarked_photo_thumbnail.dart';
import 'package:cng_pump/widgets/shared_widgets/async_state_view.dart';

Widget _buildTestApp(Widget child, {HistoryProvider? historyProvider}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => PumpProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => historyProvider ?? HistoryProvider()),
      ],
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  setUp(() {
    AppDependencies.initialize(useMock: true);
  });

  group('Admin Audit Data Binding & Provider Connection Tests', () {
    test('HistoryProvider initializes empty and binds dynamic auditSessions with rich metadata', () {
      final provider = HistoryProvider();

      // Initially empty per requirement
      expect(provider.auditSessions.isEmpty, isTrue);
      expect(provider.isEmpty, isTrue);
      expect(provider.status, equals(AsyncStatus.empty));

      // Push dynamic live captured session
      final now = DateTime.now();
      final item = CaptureHistoryItem(
        id: 'aud_dynamic_1',
        stationName: 'Super CNG Station',
        operatorName: 'Ali Khan (OP-7890)',
        modeName: 'Nozzle 1',
        dateTime: now,
        images: [
          CapturedImage(label: 'Meter', image: File('meter.jpg'), capturedAt: now),
          CapturedImage(label: 'Counter', image: File('counter.jpg'), capturedAt: now),
          CapturedImage(label: 'Micro Motion', image: File('micro.jpg'), capturedAt: now),
        ],
      );

      provider.addSession(item);

      final sessions = provider.auditSessions;
      expect(sessions.isNotEmpty, isTrue);
      expect(provider.status, equals(AsyncStatus.loaded));
      final first = sessions.first;

      // Station Name, Operator Name/ID, Timestamp, and Audit Mode
      expect(first.stationName, contains('CNG Station'));
      expect(first.operatorName, contains('OP-'));
      expect(first.modeName, isNotNull);
      expect(first.images.length, equals(3));

      // Photos contain Meter, Counter, Micro Motion labels
      final labels = first.images.map((img) => img.label).toList();
      expect(labels, contains('Meter'));
      expect(labels, contains('Counter'));
      expect(labels, contains('Micro Motion'));
    });

    test('HistoryProvider detects corruption vs in-sync sessions correctly', () {
      final provider = HistoryProvider();
      final now = DateTime.now();

      final inSyncItem = CaptureHistoryItem(
        id: 'aud_insync',
        dateTime: now,
        hasCorruption: false,
        statusText: 'IN-SYNC (0.00 KG)',
        images: [CapturedImage(label: 'Meter', image: File(''), capturedAt: now)],
      );

      final corruptItem = CaptureHistoryItem(
        id: 'aud_corrupt',
        dateTime: now.add(const Duration(minutes: 1)),
        hasCorruption: true,
        statusText: 'CORRUPTION DETECTED',
        difference: '-1.35 KG',
        images: [CapturedImage(label: 'Meter', image: File(''), capturedAt: now)],
      );

      provider.addSession(inSyncItem);
      provider.addSession(corruptItem);

      final sessions = provider.auditSessions;
      final inSyncSessions = sessions.where((s) => !s.hasCorruption).toList();
      final corruptSessions = sessions.where((s) => s.hasCorruption).toList();

      expect(inSyncSessions.isNotEmpty, isTrue);
      expect(corruptSessions.isNotEmpty, isTrue);
      expect(corruptSessions.first.statusText, equals('CORRUPTION DETECTED'));
      expect(inSyncSessions.first.statusText, contains('IN-SYNC'));
    });

    test('StationHistoryItem serialization roundtrip preserves audit fields', () {
      final now = DateTime.now();
      final item = StationHistoryItem(
        id: 'aud_test_99',
        stationName: 'Super CNG Station',
        location: 'Karachi Forecourt',
        timestamp: now,
        timeDisplay: '11:45 AM',
        isChecked: false,
        operatorName: 'Zahid Khan (OP-9012)',
        operatorId: 'OP-9012',
        auditMode: 'Nozzle 2',
        hasCorruption: true,
        statusText: 'CORRUPTION DETECTED',
        difference: '-2.10 KG',
        threshold: '1.00 KG',
        sources: const {
          'Digital Machine': '2,000.00 KG',
          'Sui Gas': '2,002.10 KG',
        },
        images: [
          CapturedImage(label: 'Meter', image: File('meter.jpg'), capturedAt: now),
          CapturedImage(label: 'Counter', image: File('counter.jpg'), capturedAt: now),
        ],
      );

      final json = item.toJson();
      final fromJson = StationHistoryItem.fromJson(json);

      expect(fromJson.id, equals(item.id));
      expect(fromJson.stationName, equals(item.stationName));
      expect(fromJson.operatorName, equals('Zahid Khan (OP-9012)'));
      expect(fromJson.auditMode, equals('Nozzle 2'));
      expect(fromJson.hasCorruption, isTrue);
      expect(fromJson.difference, equals('-2.10 KG'));
      expect(fromJson.images.length, equals(2));

      // Conversion to CaptureHistoryItem
      final captureItem = fromJson.toCaptureHistoryItem();
      expect(captureItem.id, equals(item.id));
      expect(captureItem.modeName, equals('Nozzle 2'));
      expect(captureItem.hasCorruption, isTrue);
      expect(captureItem.images.length, equals(2));
    });

    test('CaptureHistoryItem imageUrls and localPaths getters return valid lists', () {
      final now = DateTime.now();
      final item = CaptureHistoryItem(
        dateTime: now,
        images: [
          CapturedImage(
            label: 'Meter',
            image: File('local/path/meter.jpg'),
            capturedAt: now,
            imageUrl: 'https://cdn.cnghub.com/meter.jpg',
          ),
          CapturedImage(
            label: 'Counter',
            image: File('local/path/counter.jpg'),
            capturedAt: now,
            imageUrl: null,
          ),
        ],
      );

      expect(item.imageUrls.length, equals(1));
      expect(item.imageUrls.first, equals('https://cdn.cnghub.com/meter.jpg'));
      expect(item.localPaths.length, equals(2));
      expect(item.localPaths.first, contains('meter.jpg'));
    });
  });

  group('AuditSessionCard Widget Tests', () {
    testWidgets('Renders session details: Station, Operator, Mode, & Thumbnails without extra chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime(2026, 9, 26, 10, 15);
      final session = CaptureHistoryItem(
        id: 'aud_card_test',
        stationName: 'North Hub CNG',
        operatorName: 'Ali Khan (OP-7890)',
        dateTime: now,
        modeName: 'Nozzle 1',
        hasCorruption: false,
        statusText: 'IN-SYNC (0.00 KG)',
        difference: '+0.00 KG',
        images: [
          CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Micro Motion', image: File(''), capturedAt: now),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        Scaffold(
          body: AuditSessionCard(session: session),
        ),
      ));
      await tester.pumpAndSettle();

      // Station Name & Operator Name
      expect(find.text('North Hub CNG'), findsOneWidget);
      expect(find.text('Ali Khan (OP-7890)'), findsOneWidget);

      // Audit Mode pill
      expect(find.text('Nozzle 1'), findsOneWidget);

      // Thumbnails for Meter, Counter, Micro Motion
      expect(find.text('METER'), findsOneWidget);
      expect(find.text('COUNTER'), findsOneWidget);
      expect(find.text('MICRO MOTION'), findsOneWidget);

      // Status chip and Variance CTA removed per minimal header requirement
      expect(find.text('IN-SYNC'), findsNothing);
      expect(find.text('Inspect Session'), findsNothing);
    });

    testWidgets('Maintains clean minimal card without corruption tags or extra chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime(2026, 9, 26, 9, 30);
      final session = CaptureHistoryItem(
        id: 'aud_corrupt_test',
        stationName: 'Central Bay CNG',
        operatorName: 'Tariq (OP-4421)',
        dateTime: now,
        modeName: 'Meter',
        hasCorruption: true,
        statusText: 'CORRUPTION DETECTED',
        difference: '-1.35 KG',
        images: [
          CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        Scaffold(
          body: AuditSessionCard(session: session),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Central Bay CNG'), findsOneWidget);
      expect(find.text('Tariq (OP-4421)'), findsOneWidget);
      expect(find.text('CORRUPTION DETECTED'), findsNothing);
      expect(find.text('-1.35 KG'), findsNothing);
    });

    testWidgets('Tapping card calls onTap or opens Inspection view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool cardTapped = false;
      final now = DateTime.now();
      final session = CaptureHistoryItem(
        dateTime: now,
        images: [CapturedImage(label: 'Meter', image: File(''), capturedAt: now)],
      );

      await tester.pumpWidget(_buildTestApp(
        Scaffold(
          body: AuditSessionCard(
            session: session,
            onTap: () => cardTapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AuditSessionCard));
      await tester.pumpAndSettle();

      expect(cardTapped, isTrue);
    });

    testWidgets('Tapping thumbnail calls onImageTap with index', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      int tappedIndex = -1;
      final now = DateTime.now();
      final session = CaptureHistoryItem(
        dateTime: now,
        images: [
          CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        Scaffold(
          body: AuditSessionCard(
            session: session,
            onImageTap: (idx) => tappedIndex = idx,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final thumbnails = find.byType(WatermarkedPhotoThumbnail);
      expect(thumbnails, findsNWidgets(2));

      await tester.tap(thumbnails.at(1));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(1));
    });
  });

  group('AdminAuditDetailScreen & Inspection View Tests', () {
    testWidgets('Displays session metadata and photo grid without diagnostic elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime(2026, 9, 26, 10, 0);
      final session = CaptureHistoryItem(
        id: 'detail_test_01',
        stationName: 'Station #01 • North Hub',
        operatorName: 'Ali Khan (OP-7890)',
        dateTime: now,
        modeName: 'Nozzle 1',
        hasCorruption: false,
        difference: '+0.00 KG',
        threshold: '1.00 KG',
        images: [
          CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Micro Motion', image: File(''), capturedAt: now),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        AdminAuditDetailScreen(session: session),
      ));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Audit Inspection'), findsOneWidget);

      // Metadata
      expect(find.text('Station #01 • North Hub'), findsOneWidget);
      expect(find.text('Ali Khan (OP-7890)'), findsOneWidget);
      expect(find.text('Nozzle 1'), findsOneWidget);

      // Diagnostic variance and status banner removed
      expect(find.text('In-Sync & Verified'), findsNothing);
      expect(find.text('Corruption Detected'), findsNothing);
      expect(find.text('EXACT NUMERICAL READINGS & VARIANCE'), findsNothing);

      // Real Captured Watermarked Photos section
      expect(find.text('CAPTURED WATERMARKED PHOTOS (3)'), findsOneWidget);
      expect(find.text('Full-screen Zoom'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('View switcher toggles between Grid and Carousel view modes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final session = CaptureHistoryItem(
        dateTime: now,
        images: [
          CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        AdminAuditDetailScreen(session: session),
      ));
      await tester.pumpAndSettle();

      // Default is Grid view
      expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // Switch to Carousel mode
      await tester.ensureVisible(find.byIcon(Icons.view_carousel_rounded));
      await tester.tap(find.byIcon(Icons.view_carousel_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Photo 1 of 2'), findsOneWidget);

      // Switch back to Grid mode
      await tester.ensureVisible(find.byIcon(Icons.grid_view_rounded));
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
    });
  });

  group('AuditPhotoFullscreenViewer & InteractiveViewer Tests', () {
    testWidgets('Renders InteractiveViewer with pinch-to-zoom and controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime(2026, 9, 26, 12, 0);
      final images = [
        CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
        CapturedImage(label: 'Counter', image: File(''), capturedAt: now),
      ];

      await tester.pumpWidget(_buildTestApp(
        AuditPhotoFullscreenViewer(
          images: images,
          initialIndex: 0,
          stationName: 'Karachi Hub',
          operatorName: 'Ali (OP-7890)',
          modeName: 'Nozzle 1',
        ),
      ));
      await tester.pumpAndSettle();

      // InteractiveViewer present
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Top control bar
      expect(find.text('Meter'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Stamped Watermark Verified Banner
      expect(find.text('WATERMARK AUDIT VERIFIED'), findsOneWidget);
      expect(find.text('Nozzle 1'), findsOneWidget);

      // Zoom in button tap
      await tester.tap(find.byIcon(Icons.zoom_in));
      await tester.pumpAndSettle();

      // Reset zoom button tap
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('Admin Feed Integration Screens Tests', () {
    testWidgets('AdminDashboardScreen renders empty state when no sessions and dynamically renders cards when added', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final historyProvider = HistoryProvider();

      await tester.pumpWidget(_buildTestApp(
        const AdminDashboardScreen(),
        historyProvider: historyProvider,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('LIVE AUDIT FEED'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      // Clean empty state initially
      expect(find.text('No audit records yet'), findsOneWidget);

      // Now push real-time session
      final now = DateTime.now();
      historyProvider.addSession(
        CaptureHistoryItem(
          id: 'aud_live_admin',
          stationName: 'North Hub Karachi',
          operatorName: 'Ali Khan',
          modeName: 'Meter',
          dateTime: now,
          images: [
            CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Now renders live dynamic session card
      expect(find.byType(AuditSessionCard), findsOneWidget);
      expect(find.text('North Hub Karachi'), findsOneWidget);
      expect(find.text('VIEW COMPLETE AUDIT LEDGER'), findsOneWidget);
    });

    testWidgets('HistoryScreen renders clean empty state and updates dynamically when sessions are added', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final historyProvider = HistoryProvider();

      await tester.pumpWidget(_buildTestApp(
        const HistoryScreen(),
        historyProvider: historyProvider,
      ));
      await tester.pumpAndSettle();

      // Screen Header
      expect(find.text('Audit Ledger & History'), findsOneWidget);
      expect(find.text('Audit Inspection & Logs'), findsOneWidget);

      // Subtitle and Filter chips removed
      expect(find.text('Completed operator audit sessions with watermarked photos & diagnostics'), findsNothing);
      expect(find.text('All History'), findsNothing);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Last 7 Days'), findsNothing);
      expect(find.text('Last 30 Days'), findsNothing);

      // Tab switcher removed
      expect(find.text('Audit Photo Feeds'), findsNothing);
      expect(find.text('Diagnostic Variance'), findsNothing);

      // Clean empty state shown
      expect(find.text('No audit history found'), findsOneWidget);

      // Add dynamic real-time session
      final now = DateTime.now();
      historyProvider.addSession(
        CaptureHistoryItem(
          id: 'aud_dyn_hist',
          stationName: 'West Station',
          operatorName: 'Zahid Khan',
          modeName: 'Nozzle 1',
          dateTime: now,
          images: [
            CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // AuditSessionCards dynamically rendered in the visual feed
      expect(find.byType(AuditSessionCard), findsOneWidget);
      expect(find.text('West Station'), findsOneWidget);
    });
  });
}
