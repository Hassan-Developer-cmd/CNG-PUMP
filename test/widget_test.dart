import 'dart:io';

import 'package:cng_pump/models/capture_history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/main.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/screens/camera_screen/camera_screen.dart';
import 'package:cng_pump/screens/result_screen/result_screen.dart';
import 'package:cng_pump/widgets/camera/camera_control_bar.dart';
import 'package:provider/provider.dart';

void main() {
  group('CngReadingItem Tests', () {
    test('Required item is incomplete without image and input data', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      expect(item.hasImage, isFalse);
      expect(item.hasInputData, isFalse);
      expect(item.isComplete, isFalse);
    });

    test('Required item becomes complete with image and input data', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('test.jpg');
      item.inputData = '2104.50';

      expect(item.hasImage, isTrue);
      expect(item.hasInputData, isTrue);
      expect(item.isComplete, isTrue);
    });

    test('Required item remains incomplete when input data is empty', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('test.jpg');
      item.inputData = '   ';

      expect(item.hasImage, isTrue);
      expect(item.hasInputData, isFalse);
      expect(item.isComplete, isFalse);
    });

    test(
      'Optional item is considered complete without image or input data',
      () {
        final item = CngReadingItem(
          type: CngReadingType.microMotion,
          title: 'Micro Motion',
          isRequired: false,
          icon: Icons.speed_outlined,
        );

        expect(item.isComplete, isTrue);
      },
    );

    test('Reset clears image and input data', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('test.jpg');
      item.inputData = '1234';

      item.reset();

      expect(item.image, isNull);
      expect(item.inputData, isEmpty);
      expect(item.isComplete, isFalse);
    });
  });

  group('CaptureProvider Tests', () {
    test('Initializes with 3 capture items', () {
      final provider = CaptureProvider();

      expect(provider.readingItems.length, equals(3));

      expect(provider.readingItems[0].title, equals('Digital Machine'));

      expect(provider.readingItems[1].title, equals('Manual Data'));

      expect(provider.readingItems[2].title, equals('Micro Motion'));

      expect(provider.readingItems[0].isRequired, isTrue);
      expect(provider.readingItems[1].isRequired, isTrue);
      expect(provider.readingItems[2].isRequired, isFalse);
    });

    test('Result cannot be viewed until required pictures are captured', () {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);
    });

    test('Stores input data correctly', () {
      final provider = CaptureProvider();

      provider.setInputData(0, '2104.50 KG');

      expect(provider.readingItems[0].inputData, equals('2104.50 KG'));

      expect(provider.readingItems[0].hasInputData, isTrue);
    });

    test('Stores input data by reading type', () {
      final provider = CaptureProvider();

      provider.setInputDataByType(CngReadingType.digitalMachine, '2104.50 KG');

      expect(
        provider.getItemByType(CngReadingType.digitalMachine).inputData,
        equals('2104.50 KG'),
      );
    });

    test('Stores captured image correctly', () async {
      final provider = CaptureProvider();
      final file = File('test.jpg');

      await provider.setImage(0, file);

      expect(provider.readingItems[0].image, equals(file));
      expect(provider.readingItems[0].hasImage, isTrue);
    });

    test('Stores captured image by reading type', () async {
      final provider = CaptureProvider();
      final file = File('digital_machine.jpg');

      await provider.setImageByType(CngReadingType.digitalMachine, file);

      expect(
        provider.getItemByType(CngReadingType.digitalMachine).image,
        equals(file),
      );
    });

    testWidgets(
      'Dashboard requires required pictures before View Result is enabled',
      (WidgetTester tester) async {
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
            child: const MaterialApp(
              home: Scaffold(body: Text('Capture Flow')),
            ),
          ),
        );

        // No pictures captured yet.
        expect(provider.canViewResult, isFalse);

        // Capture Digital Machine.
        await provider.setImage(0, File('digital_machine.jpg'));

        // Only one required picture exists.
        expect(provider.canViewResult, isFalse);

        // Capture Manual Data.
        await provider.setImage(1, File('manual_data.jpg'));

        // Both required pictures exist.
        // No Input Data is required.
        expect(provider.canViewResult, isTrue);
      },
    );

    test('Optional Micro Motion does not prevent viewing result', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('digital_machine.jpg'));
      provider.setInputData(0, '2104.50');

      await provider.setImage(1, File('manual_data.jpg'));
      provider.setInputData(1, '2103.15');

      // Micro Motion is optional.
      expect(provider.readingItems[2].isRequired, isFalse);

      expect(provider.canViewResult, isTrue);
    });

    test('Clears a single image correctly', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('test.jpg'));

      expect(provider.readingItems[0].hasImage, isTrue);

      provider.clearImage(0);

      expect(provider.readingItems[0].hasImage, isFalse);
    });

    test('clearAll removes all captured data', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('digital_machine.jpg'));

      await provider.setImage(1, File('manual_data.jpg'));

      provider.setInputData(0, '2104.50');

      provider.setInputData(1, '2103.15');

      expect(provider.canViewResult, isTrue);

      provider.clearAll();

      expect(provider.readingItems[0].image, isNull);
      expect(provider.readingItems[1].image, isNull);
      expect(provider.readingItems[0].inputData, isEmpty);
      expect(provider.readingItems[1].inputData, isEmpty);
      expect(provider.canViewResult, isFalse);
    });

    test('No comparison or difference calculation is required', () {
      final provider = CaptureProvider();

      // The capture provider only manages:
      // 1. Input data
      // 2. Captured images
      //
      // There is intentionally no comparison result,
      // difference calculation, OCR result, or corruption detection.

      expect(provider.readingItems.length, equals(3));
      expect(provider.canViewResult, isFalse);
    });
  });

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
            inputData: '2104.50',
          ),
        ],
      );

      expect(provider.records.length, equals(1));
      expect(provider.records.first.images.length, equals(1));
      expect(
        provider.records.first.images.first.label,
        equals('Digital Machine'),
      );
      expect(provider.records.first.images.first.inputData, equals('2104.50'));
    });

    test('Does not add empty capture records', () {
      final provider = HistoryProvider();

      provider.addCapture(images: []);

      expect(provider.records, isEmpty);
    });

    test('Clear history removes all capture records', () {
      final provider = HistoryProvider();

      provider.addCapture(
        images: [
          CapturedImage(
            label: 'Counter',
            image: File('counter.jpg'),
            inputData: '1234',
          ),
        ],
      );

      expect(provider.isEmpty, isFalse);

      provider.clearAll();

      expect(provider.records, isEmpty);
      expect(provider.isEmpty, isTrue);
    });
  });

  testWidgets(
    'DashboardScreen displays CNG Hub with capture sections and Ali header',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CaptureProvider()),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CNG Hub'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);

      expect(find.text('Digital Machine'), findsOneWidget);
      expect(find.text('Manual Data'), findsOneWidget);
      expect(find.text('Micro Motion'), findsOneWidget);
      expect(find.text('Sui Gas'), findsOneWidget);

      expect(find.text('REQUIRED'), findsNWidgets(2));
      expect(find.text('OPTIONAL'), findsOneWidget);

      // Comparison has been removed.
      expect(find.text('Compare Data'), findsNothing);

      // New capture-only flow.
      expect(find.text('View Result'), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard requires input data and pictures before View Result is enabled',
    (WidgetTester tester) async {
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

      provider.setInputData(0, '2104.50');

      await provider.setImage(0, File('digital_machine.jpg'));

      provider.setInputData(1, '2103.15');

      await provider.setImage(1, File('manual_data.jpg'));

      await tester.pump();

      expect(provider.canViewResult, isTrue);
    },
  );

  testWidgets('ResultScreen displays captured pictures and input data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = CaptureProvider();

    await provider.setImage(0, File('digital_machine.jpg'));
    provider.setInputData(0, '2104.50 KG');

    await provider.setImage(1, File('manual_data.jpg'));
    provider.setInputData(1, '2103.15 KG');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: ResultScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('CAPTURED PICTURES'), findsOneWidget);
    expect(
      find.text('Your captured pictures are shown below.'),
      findsOneWidget,
    );

    expect(find.text('Digital Machine'), findsOneWidget);
    expect(find.text('Manual Data'), findsOneWidget);

    expect(find.text('2104.50 KG'), findsOneWidget);
    expect(find.text('2103.15 KG'), findsOneWidget);

    // Old comparison UI must not exist.
    expect(find.text('Comparison Result'), findsNothing);
    expect(find.text('Corruption Detected'), findsNothing);
    expect(find.text('Readings Verified'), findsNothing);
    expect(find.text('COMPARISON DETAILS'), findsNothing);
    expect(find.text('1.35 KG'), findsNothing);
  });

  testWidgets(
    'ResultScreen displays Not Provided when optional input data is empty',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();

      await provider.setImage(0, File('digital_machine.jpg'));

      provider.setInputData(0, '2104.50');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: ResultScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Digital Machine'), findsOneWidget);
      expect(find.text('2104.50'), findsOneWidget);
    },
  );

  testWidgets('CameraScreen displays title, close button and controls', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CameraScreen()));

    // Camera initialization is asynchronous.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Scan Meter'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(CameraControlBar), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });
}
