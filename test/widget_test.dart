import 'dart:io';

import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/screens/camera_screen/camera_screen.dart';
import 'package:cng_pump/screens/dashboard/dashboard_screen.dart';
import 'package:cng_pump/screens/result_screen/result_screen.dart';
import 'package:cng_pump/widgets/camera/camera_control_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  final testDateTime = DateTime(2026, 9, 16, 12, 30, 45);

  // CNG READING ITEM TESTS
  group('CngReadingItem Tests', () {
    test('Required item is incomplete without an image', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      expect(item.hasImage, isFalse);
      expect(item.isComplete, isFalse);
      expect(item.capturedAt, isNull);
    });

    test('Required item becomes complete with an image', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('test.jpg');
      item.capturedAt = testDateTime;

      expect(item.hasImage, isTrue);
      expect(item.isComplete, isTrue);
      expect(item.capturedAt, equals(testDateTime));
    });

    test('Required item remains incomplete when image is missing', () {
      final item = CngReadingItem(
        type: CngReadingType.manualData,
        title: 'Manual Data',
        isRequired: true,
        icon: Icons.edit_note_outlined,
      );

      expect(item.hasImage, isFalse);
      expect(item.isComplete, isFalse);
    });

    test('Optional item is complete without an image', () {
      final item = CngReadingItem(
        type: CngReadingType.microMotion,
        title: 'Micro Motion',
        isRequired: false,
        icon: Icons.speed_outlined,
      );

      expect(item.hasImage, isFalse);
      expect(item.isComplete, isTrue);
    });

    test('Optional item remains complete with an image', () {
      final item = CngReadingItem(
        type: CngReadingType.microMotion,
        title: 'Micro Motion',
        isRequired: false,
        icon: Icons.speed_outlined,
      );

      item.image = File('micro_motion.jpg');
      item.capturedAt = testDateTime;

      expect(item.hasImage, isTrue);
      expect(item.isComplete, isTrue);
      expect(item.capturedAt, equals(testDateTime));
    });

    test('Reset clears the captured image and timestamp', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('test.jpg');
      item.capturedAt = testDateTime;

      expect(item.hasImage, isTrue);
      expect(item.isComplete, isTrue);
      expect(item.capturedAt, equals(testDateTime));

      item.reset();

      expect(item.image, isNull);
      expect(item.capturedAt, isNull);
      expect(item.hasImage, isFalse);
      expect(item.isComplete, isFalse);
    });

    test('Reset keeps optional item complete', () {
      final item = CngReadingItem(
        type: CngReadingType.microMotion,
        title: 'Micro Motion',
        isRequired: false,
        icon: Icons.speed_outlined,
      );

      item.image = File('micro_motion.jpg');
      item.capturedAt = testDateTime;

      expect(item.isComplete, isTrue);

      item.reset();

      expect(item.image, isNull);
      expect(item.capturedAt, isNull);
      expect(item.hasImage, isFalse);
      expect(item.isComplete, isTrue);
    });
  });

  // CAPTURE PROVIDER TESTS
  group('CaptureProvider Tests', () {
    test('Initializes with three capture items', () {
      final provider = CaptureProvider();

      expect(provider.readingItems.length, equals(3));

      expect(provider.readingItems[0].title, equals('VB1'));

      expect(provider.readingItems[1].title, equals('VS1'));

      expect(provider.readingItems[2].title, equals('R Flow'));
    });

    test('Initializes required and optional items correctly', () {
      final provider = CaptureProvider();

      expect(provider.readingItems[0].isRequired, isTrue);
      expect(provider.readingItems[1].isRequired, isTrue);
      expect(provider.readingItems[2].isRequired, isFalse);
    });

    test('Initial state cannot view result', () {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);
    });

    test('Required images must be captured before viewing result', () async {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);

      await provider.setImage(0, File('vb1.jpg'), testDateTime);

      expect(provider.canViewResult, isFalse);

      await provider.setImage(1, File('vs1.jpg'), testDateTime);

      expect(provider.canViewResult, isTrue);
    });

    test('Optional Micro Motion does not prevent viewing result', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('vb1.jpg'), testDateTime);

      await provider.setImage(1, File('vs1.jpg'), testDateTime);

      expect(provider.readingItems[2].isRequired, isFalse);

      expect(provider.canViewResult, isTrue);
    });

    test('All three images can be captured', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('vb1.jpg'), testDateTime);

      await provider.setImage(1, File('vs1.jpg'), testDateTime);

      await provider.setImage(2, File('r_flow.jpg'), testDateTime);

      expect(provider.readingItems[0].hasImage, isTrue);

      expect(provider.readingItems[1].hasImage, isTrue);

      expect(provider.readingItems[2].hasImage, isTrue);

      expect(provider.canViewResult, isTrue);
    });

    test('Stores captured image and timestamp correctly', () async {
      final provider = CaptureProvider();
      final file = File('test.jpg');

      await provider.setImage(0, file, testDateTime);

      expect(provider.readingItems[0].image, equals(file));

      expect(provider.readingItems[0].capturedAt, equals(testDateTime));

      expect(provider.readingItems[0].hasImage, isTrue);
    });

    test('Stores captured image by reading type', () async {
      final provider = CaptureProvider();
      final file = File('vb1.jpg');

      await provider.setImageByType(
        CngReadingType.vb1,
        file,
        testDateTime,
      );

      final item = provider.getItemByType(CngReadingType.vb1);

      expect(item.image, equals(file));
      expect(item.capturedAt, equals(testDateTime));
      expect(item.hasImage, isTrue);
    });

    test('Stores VS1 image by reading type', () async {
      final provider = CaptureProvider();
      await provider.setImageByType(
        CngReadingType.vb1,
        File('vb1.jpg'),
        testDateTime,
      );

      final file = File('vs1.jpg');
      await provider.setImageByType(
        CngReadingType.vs1,
        file,
        testDateTime,
      );

      final item = provider.getItemByType(CngReadingType.vs1);

      expect(item.image, equals(file));
      expect(item.capturedAt, equals(testDateTime));
      expect(item.hasImage, isTrue);

      provider.dispose();
    });

    test('Stores R Flow image by reading type', () async {
      final provider = CaptureProvider();
      await provider.setImageByType(
        CngReadingType.vb1,
        File('vb1.jpg'),
        testDateTime,
      );
      await provider.setImageByType(
        CngReadingType.vs1,
        File('vs1.jpg'),
        testDateTime,
      );

      final file = File('r_flow.jpg');
      await provider.setImageByType(
        CngReadingType.rFlow,
        file,
        testDateTime,
      );

      final item = provider.getItemByType(CngReadingType.rFlow);

      expect(item.image, equals(file));
      expect(item.capturedAt, equals(testDateTime));
      expect(item.hasImage, isTrue);

      provider.dispose();
    });

    test('Getting item by type returns the correct item', () {
      final provider = CaptureProvider();

      final vb1 = provider.getItemByType(CngReadingType.vb1);
      final vs1 = provider.getItemByType(CngReadingType.vs1);
      final rFlow = provider.getItemByType(CngReadingType.rFlow);

      expect(vb1.title, equals('VB1'));
      expect(vs1.title, equals('VS1'));
      expect(rFlow.title, equals('R Flow'));
    });

    test('No comparison or input data is required', () {
      final provider = CaptureProvider();

      expect(provider.readingItems.length, equals(3));
      expect(provider.canViewResult, isFalse);
    });
  });

  // HISTORY PROVIDER TESTS
  group('HistoryProvider Tests', () {
    test('Starts with empty capture history', () {
      final provider = HistoryProvider();

      expect(provider.records, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test('Adds a captured record to history', () {
      final provider = HistoryProvider();

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Digital Machine',
            image: File('digital_machine.jpg'),
            capturedAt: testDateTime,
          ),
        ],
      );

      expect(provider.records.length, equals(1));

      expect(provider.records.first.images.length, equals(1));

      expect(
        provider.records.first.images.first.label,
        equals('Digital Machine'),
      );

      expect(
        provider.records.first.images.first.capturedAt,
        equals(testDateTime),
      );
    });

    test('Adds multiple captured images to history', () {
      final provider = HistoryProvider();

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Digital Machine',
            image: File('digital_machine.jpg'),
            capturedAt: testDateTime,
          ),
          CapturedImage(
            label: 'Manual Data',
            image: File('manual_data.jpg'),
            capturedAt: testDateTime.add(const Duration(seconds: 10)),
          ),
        ],
      );

      expect(provider.records.length, equals(1));

      expect(provider.records.first.images.length, equals(2));

      expect(provider.records.first.images[0].label, equals('Digital Machine'));

      expect(provider.records.first.images[1].label, equals('Manual Data'));

      expect(provider.records.first.images[0].capturedAt, equals(testDateTime));

      expect(
        provider.records.first.images[1].capturedAt,
        equals(testDateTime.add(const Duration(seconds: 10))),
      );
    });

    test('Does not add empty capture records', () {
      final provider = HistoryProvider();

      provider.addCapture(images: []);

      expect(provider.records, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test('Clear history removes all capture records', () {
      final provider = HistoryProvider();

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Digital Machine',
            image: File('digital_machine.jpg'),
            capturedAt: testDateTime,
          ),
        ],
      );

      expect(provider.isEmpty, isFalse);

      provider.clearAll();

      expect(provider.records, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test('Multiple capture records can be stored', () {
      final provider = HistoryProvider();

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Digital Machine',
            image: File('digital_machine_1.jpg'),
            capturedAt: testDateTime,
          ),
        ],
      );

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Digital Machine',
            image: File('digital_machine_2.jpg'),
            capturedAt: testDateTime.add(const Duration(minutes: 5)),
          ),
        ],
      );

      expect(provider.records.length, equals(2));
    });
  });

  // DASHBOARD TESTS
  testWidgets('Dashboard displays CNG Hub and capture sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CaptureProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CNG Hub'), findsOneWidget);

    expect(find.text('VB1'), findsOneWidget);

    expect(find.text('VS1'), findsOneWidget);

    expect(find.text('R Flow'), findsOneWidget);

    expect(find.text('REQUIRED'), findsNWidgets(2));

    expect(find.text('OPTIONAL'), findsOneWidget);

    expect(find.text('Compare Data'), findsNothing);

    expect(find.text('Save Data'), findsOneWidget);
  });

  testWidgets('Dashboard starts with result unavailable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    final provider = CaptureProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Capture Flow'))),
      ),
    );

    expect(provider.canViewResult, isFalse);
  });

  testWidgets('Dashboard enables result after required images are captured', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    final provider = CaptureProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Capture Flow'))),
      ),
    );

    expect(provider.canViewResult, isFalse);

    await provider.setImage(0, File('vb1.jpg'), testDateTime);

    expect(provider.canViewResult, isFalse);

    await provider.setImage(1, File('vs1.jpg'), testDateTime);

    await tester.pump();

    expect(provider.canViewResult, isTrue);
    provider.dispose();
  });

  // RESULT SCREEN TESTS
  testWidgets('ResultScreen displays captured pictures', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    final provider = CaptureProvider();

    await provider.setImage(0, File('vb1.jpg'), testDateTime);

    await provider.setImage(1, File('vs1.jpg'), testDateTime);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(home: ResultScreen()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Result'), findsOneWidget);

    expect(find.text('CAPTURED PICTURES'), findsOneWidget);

    expect(
      find.text('Your captured pictures are shown below.'),
      findsOneWidget,
    );

    expect(find.text('VB1'), findsOneWidget);

    expect(find.text('VS1'), findsOneWidget);

    expect(find.text('Comparison Result'), findsNothing);

    expect(find.text('Corruption Detected'), findsNothing);

    expect(find.text('Readings Verified'), findsNothing);

    expect(find.text('COMPARISON DETAILS'), findsNothing);
    provider.dispose();
  });

  testWidgets('ResultScreen displays all captured sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    final provider = CaptureProvider();

    await provider.setImage(0, File('vb1.jpg'), testDateTime);

    await provider.setImage(1, File('vs1.jpg'), testDateTime);

    await provider.setImage(2, File('r_flow.jpg'), testDateTime);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(home: ResultScreen()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('VB1'), findsOneWidget);

    expect(find.text('VS1'), findsOneWidget);

    expect(find.text('R Flow'), findsOneWidget);
    provider.dispose();
  });

  // CAMERA SCREEN TESTS
  testWidgets('CameraScreen displays title, close button and controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CameraScreen()));

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Scan Meter'), findsOneWidget);

    expect(find.byIcon(Icons.close), findsOneWidget);

    expect(find.byType(CameraControlBar), findsOneWidget);

    expect(find.byIcon(Icons.history), findsOneWidget);
  });
}
