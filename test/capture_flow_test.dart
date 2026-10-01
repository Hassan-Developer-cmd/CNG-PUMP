import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/services/image_timestamp_service.dart';
import 'package:cng_pump/widgets/shared_widgets/exit_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:cng_pump/screens/dashboard/dashboard_screen.dart';
import 'package:cng_pump/screens/result_screen/result_screen.dart';
import 'package:cng_pump/widgets/shared_widgets/source_selector_dropdown.dart';

void main() {
  final testDateTime = DateTime(2026, 9, 16, 12, 30, 45);

  group('CaptureProvider - Meter and Nozzle', () {
    test('Meter shows VB1, VS1 and optional R Flow', () {
      final provider = CaptureProvider();

      expect(provider.primarySourceMode, PrimarySourceMode.meter);

      expect(provider.readingItems.map((e) => e.title), [
        'VB1',
        'VS1',
        'R Flow',
      ]);

      expect(provider.readingItems[0].isRequired, isTrue);

      expect(provider.readingItems[1].isRequired, isTrue);

      expect(provider.readingItems[2].isRequired, isFalse);

      provider.dispose();
    });

    test('Nozzle modes load only Meter, Counter, and Micro Motion in currentReadingItems (Nozzle card removed)', () {
      final provider = CaptureProvider();

      for (final mode in [
        PrimarySourceMode.nozzle1,
        PrimarySourceMode.nozzle2,
        PrimarySourceMode.nozzle3,
        PrimarySourceMode.nozzle4,
      ]) {
        provider.setPrimarySourceMode(mode);
        expect(provider.currentReadingItems.length, 3);
        expect(provider.readingItems.length, 3);
        expect(provider.currentReadingItems.map((e) => e.title).toList(), [
          'Meter',
          'Counter',
          'Micro Motion',
        ]);
        expect(provider.currentReadingItems[0].isRequired, isTrue);
        expect(provider.currentReadingItems[1].isRequired, isTrue);
        expect(provider.currentReadingItems[2].isRequired, isFalse);
        expect(provider.currentReadingItems.any((e) => e.title.contains('Nozzle')), isFalse);
      }

      provider.dispose();
    });

    test('Validation and canViewResult require only the required cards (Meter and Counter)', () async {
      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);

      expect(provider.canViewResult, isFalse);
      expect(provider.isComplete, isFalse);

      // Capture Meter (required)
      await provider.setImage(0, File('meter.jpg'), testDateTime);
      expect(provider.canViewResult, isFalse);
      expect(provider.isComplete, isFalse);

      // Capture Counter (required)
      await provider.setImage(1, File('counter.jpg'), testDateTime.add(const Duration(seconds: 10)));
      expect(provider.canViewResult, isTrue);
      expect(provider.isComplete, isTrue);

      // Micro Motion is optional, remains uncaptured
      expect(provider.currentReadingItems[2].hasImage, isFalse);

      provider.dispose();
    });

    test('View Result requires only the two required pictures', () async {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);

      await provider.setImage(0, File('first.jpg'), testDateTime);

      expect(provider.canViewResult, isFalse);

      await provider.setImage(
        1,
        File('second.jpg'),
        testDateTime.add(const Duration(seconds: 10)),
      );

      expect(provider.canViewResult, isTrue);

      // The optional third picture is not required.
      expect(provider.readingItems[2].hasImage, isFalse);

      // Verify timestamps are stored.
      expect(provider.readingItems[0].capturedAt, equals(testDateTime));

      expect(
        provider.readingItems[1].capturedAt,
        equals(testDateTime.add(const Duration(seconds: 10))),
      );

      provider.dispose();
    });

    test(
      'nextCaptureIndex points to the next required picture',
      () async {
        final provider = CaptureProvider();

        expect(provider.nextCaptureIndex, 0);

        await provider.setImage(0, File('first.jpg'), testDateTime);

        expect(provider.nextCaptureIndex, 1);

        await provider.setImage(1, File('second.jpg'), testDateTime);

        expect(provider.nextCaptureIndex, -1);

        provider.dispose();
      },
    );

    test('Timer starts after first required picture and remains active after second', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('first.jpg'), testDateTime);

      expect(provider.timerActive, isTrue);
      expect(provider.isTimerVisible, isTrue);
      expect(provider.remainingSeconds, 120);
      expect(provider.nextCaptureIndex, 1);
      expect(provider.readingItems[0].capturedAt, equals(testDateTime));

      // After second picture, timer must remain active and visible until Save Data is clicked!
      await provider.setImage(1, File('second.jpg'), testDateTime.add(const Duration(seconds: 15)));

      expect(provider.timerActive, isTrue);
      expect(provider.isTimerVisible, isTrue);
      expect(provider.canViewResult, isTrue);

      // When Save Data is clicked, stopAndRemoveTimer is called.
      provider.stopAndRemoveTimer();

      expect(provider.timerActive, isFalse);
      expect(provider.isTimerVisible, isFalse);

      provider.dispose();
    });

    test('Clearing an image also clears its timestamp', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('first.jpg'), testDateTime);

      expect(provider.readingItems[0].hasImage, isTrue);

      expect(provider.readingItems[0].capturedAt, equals(testDateTime));

      provider.clearImage(0);

      expect(provider.readingItems[0].image, isNull);

      expect(provider.readingItems[0].capturedAt, isNull);

      expect(provider.readingItems[0].hasImage, isFalse);

      provider.dispose();
    });

    test('Different pictures can have different timestamps', () async {
      final provider = CaptureProvider();

      final firstCapturedAt = DateTime(2026, 9, 16, 12, 30, 10);

      final secondCapturedAt = DateTime(2026, 9, 16, 12, 31, 25);

      await provider.setImage(0, File('first.jpg'), firstCapturedAt);

      await provider.setImage(1, File('second.jpg'), secondCapturedAt);

      expect(provider.readingItems[0].capturedAt, equals(firstCapturedAt));

      expect(provider.readingItems[1].capturedAt, equals(secondCapturedAt));

      expect(
        provider.readingItems[0].capturedAt,
        isNot(equals(provider.readingItems[1].capturedAt)),
      );

      provider.dispose();
    });
  });

  group('ImageTimestampService Tests', () {
    test('formatTimestamp formats date and time correctly', () {
      final dt = DateTime(2026, 9, 16, 15, 45, 30);
      final formatted = ImageTimestampService.formatTimestamp(dt);
      expect(formatted, equals('16/09/2026 3:45:30 PM'));

      final dtMorning = DateTime(2026, 1, 5, 9, 5, 7);
      final formattedMorning = ImageTimestampService.formatTimestamp(dtMorning);
      expect(formattedMorning, equals('05/01/2026 9:05:07 AM'));
    });

    test('addTimestamp successfully embeds timestamp onto an image file', () async {
      // Create a test image in memory
      final testImg = img.Image(width: 800, height: 600);
      img.fill(testImg, color: img.ColorRgb8(200, 200, 200));
      final bytes = img.encodeJpg(testImg);

      final tempDir = Directory.systemTemp;
      final sourceFile = File('${tempDir.path}/test_source_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await sourceFile.writeAsBytes(bytes);

      final stampedFile = await ImageTimestampService.addTimestamp(
        sourceFile,
        capturedAt: DateTime(2026, 9, 16, 14, 20, 10),
      );

      expect(await stampedFile.exists(), isTrue);
      final stampedBytes = await stampedFile.readAsBytes();
      expect(stampedBytes.length, greaterThan(0));

      final decoded = img.decodeImage(stampedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(800));
      expect(decoded.height, equals(600));

      // Cleanup
      if (await sourceFile.exists()) await sourceFile.delete();
      if (await stampedFile.exists()) await stampedFile.delete();
    });
  });

  group('ExitConfirmationDialog Tests', () {
    testWidgets('Renders Exit App? dialog with Cancel and Exit options', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: ExitConfirmationDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exit App?'), findsOneWidget);
      expect(find.text('Are you sure you want to exit the app?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });
  });

  group('Nozzle History Tests', () {
    test('Records history for all 4 nozzles with mode name and timestamps', () {
      final historyProvider = HistoryProvider();

      expect(historyProvider.isEmpty, isTrue);

      final images = [
        CapturedImage(
          label: 'Nozzle 1',
          image: File('n1.jpg'),
          capturedAt: testDateTime,
        ),
        CapturedImage(
          label: 'Nozzle 2',
          image: File('n2.jpg'),
          capturedAt: testDateTime.add(const Duration(seconds: 15)),
        ),
        CapturedImage(
          label: 'Nozzle 3',
          image: File('n3.jpg'),
          capturedAt: testDateTime.add(const Duration(seconds: 30)),
        ),
        CapturedImage(
          label: 'Nozzle 4',
          image: File('n4.jpg'),
          capturedAt: testDateTime.add(const Duration(seconds: 45)),
        ),
      ];

      historyProvider.addCapture(images: images, modeName: 'Nozzle');

      expect(historyProvider.records.length, 1);
      final record = historyProvider.records.first;
      expect(record.modeName, equals('Nozzle'));
      expect(record.images.length, 4);
      expect(record.images[0].label, equals('Nozzle 1'));
      expect(record.images[1].label, equals('Nozzle 2'));
      expect(record.images[2].label, equals('Nozzle 3'));
      expect(record.images[3].label, equals('Nozzle 4'));
    });
  });

  group('Nozzle Selection and Ali Prompt UI Tests', () {
    testWidgets('Dashboard in Nozzle 1 mode hides Nozzle card and only shows Meter, Counter, Micro Motion cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dropdown button displays 'Nozzle 1'
      expect(find.text('Nozzle 1'), findsOneWidget); // Only in dropdown pill button

      // Nozzle capture card must be completely hidden / removed
      expect(find.text('Ali • Take this pic from Nozzle 1'), findsNothing);
      expect(find.text('Ali take this pic from Nozzle 1'), findsNothing);

      // Exactly these 3 cards are visible: Meter, Counter, Micro Motion
      expect(find.text('Meter'), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('Micro Motion'), findsOneWidget);

      // Sui Gas items are specific to Meter mode
      expect(find.text('VB1'), findsNothing);
      expect(find.text('VS1'), findsNothing);
      expect(find.text('R Flow'), findsNothing);

      provider.dispose();
    });

    testWidgets('Dashboard in Nozzle 2 mode hides Nozzle card and shows selected nozzle in dropdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle2);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nozzle 2'), findsOneWidget);
      expect(find.text('Ali • Take this pic from Nozzle 2'), findsNothing);
      expect(find.text('Ali take this pic from Nozzle 2'), findsNothing);

      // Exactly the 3 cards are present
      expect(find.text('Meter'), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('Micro Motion'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Save Data button enables only when Meter and Counter are captured and excludes Nozzle card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Save Data button is disabled initially
      expect(provider.canViewResult, isFalse);
      expect(provider.isComplete, isFalse);

      // Capture Meter only -> still incomplete
      await provider.setImageByType(CngReadingType.meter, File('meter.jpg'), testDateTime);
      await tester.pumpAndSettle();
      expect(provider.canViewResult, isFalse);
      expect(provider.isComplete, isFalse);

      // Capture Counter -> now complete! Save Data is enabled
      await provider.setImageByType(CngReadingType.counter, File('counter.jpg'), testDateTime);
      await tester.pumpAndSettle();
      expect(provider.canViewResult, isTrue);
      expect(provider.isComplete, isTrue);

      provider.dispose();
    });

    testWidgets('ResultScreen displays Meter, Counter, and Micro Motion captured without Nozzle card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);
      await provider.setImageByType(CngReadingType.meter, File('meter.jpg'), testDateTime);
      await provider.setImageByType(CngReadingType.counter, File('counter.jpg'), testDateTime);
      await provider.setImageByType(CngReadingType.microMotion, File('micro.jpg'), testDateTime);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: ResultScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nozzle 1'), findsNothing);
      expect(find.text('Meter'), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('Micro Motion'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('DashboardScreen in Meter mode displays VB1, VS1, R Flow and hides Sui Gas header, Meter, Counter, Micro Motion cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.meter);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sui Gas header and Select Sui Gas dropdown should NOT be present
      expect(find.text('Sui Gas'), findsNothing);
      expect(find.text('Select Sui Gas'), findsNothing);

      // VB1, VS1, R Flow reading items should be present
      expect(find.text('VB1'), findsOneWidget);
      expect(find.text('VS1'), findsOneWidget);
      expect(find.text('R Flow'), findsOneWidget);

      // Meter, Counter, Micro Motion cards should NOT be present
      expect(find.text('Counter'), findsNothing);
      expect(find.text('Micro Motion'), findsNothing);
      expect(find.byIcon(Icons.av_timer_outlined), findsNothing);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);

      provider.dispose();
    });

    testWidgets('UserProfileHeader dynamically updates user name with selected mode upon mode switch', (tester) async {
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
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial Meter mode -> "Ali Meter"
      expect(provider.selectedMode, 'Meter');
      expect(provider.displayUserName, 'Ali Meter');
      expect(find.text('Ali Meter'), findsOneWidget);

      // Switch to Nozzle 1 -> "Ali Nozzle 1"
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);
      await tester.pumpAndSettle();
      expect(provider.selectedMode, 'Nozzle 1');
      expect(provider.displayUserName, 'Ali Nozzle 1');
      expect(find.text('Ali Nozzle 1'), findsOneWidget);
      expect(find.text('Ali Meter'), findsNothing);

      // Switch to Nozzle 2 -> "Ali Nozzle 2"
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle2);
      await tester.pumpAndSettle();
      expect(provider.selectedMode, 'Nozzle 2');
      expect(provider.displayUserName, 'Ali Nozzle 2');
      expect(find.text('Ali Nozzle 2'), findsOneWidget);

      // Switch to Nozzle 3 -> "Ali Nozzle 3"
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle3);
      await tester.pumpAndSettle();
      expect(provider.selectedMode, 'Nozzle 3');
      expect(provider.displayUserName, 'Ali Nozzle 3');
      expect(find.text('Ali Nozzle 3'), findsOneWidget);

      // Switch to Nozzle 4 -> "Ali Nozzle 4"
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle4);
      await tester.pumpAndSettle();
      expect(provider.selectedMode, 'Nozzle 4');
      expect(provider.displayUserName, 'Ali Nozzle 4');
      expect(find.text('Ali Nozzle 4'), findsOneWidget);

      // Switch back to Meter -> "Ali Meter"
      provider.setPrimarySourceMode(PrimarySourceMode.meter);
      await tester.pumpAndSettle();
      expect(provider.selectedMode, 'Meter');
      expect(provider.displayUserName, 'Ali Meter');
      expect(find.text('Ali Meter'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('SourceSelectorDropdown opens floating overlay without pushing layout and dismisses on outside tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final provider = CaptureProvider();
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Counter card position before dropdown is opened
      final counterCardFinder = find.text('Counter');
      expect(counterCardFinder, findsOneWidget);
      final counterInitialOffset = tester.getTopLeft(counterCardFinder);

      // Tap dropdown pill button
      final dropdownPill = find.text('Nozzle 1');
      expect(dropdownPill, findsOneWidget);
      await tester.tap(dropdownPill);
      await tester.pumpAndSettle();

      // Overlay is open: menu options are visible
      expect(find.text('Nozzle 2'), findsOneWidget);
      expect(find.text('Nozzle 3'), findsOneWidget);
      expect(find.text('Nozzle 4'), findsOneWidget);

      // Crucial: Counter card must NOT be pushed down
      final counterAfterOpenOffset = tester.getTopLeft(counterCardFinder);
      expect(counterAfterOpenOffset.dy, equals(counterInitialOffset.dy));

      // Tap outside the dropdown (e.g. top-left corner of the screen)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dropdown overlay is now dismissed
      expect(find.text('Nozzle 2'), findsNothing);
      expect(find.text('Nozzle 3'), findsNothing);

      // Now tap dropdown again and select Nozzle 3 from the menu
      await tester.tap(find.text('Nozzle 1'));
      await tester.pumpAndSettle();
      expect(find.text('Nozzle 3'), findsOneWidget);

      await tester.tap(find.text('Nozzle 3'));
      await tester.pumpAndSettle();

      // Mode changed to Nozzle 3 and dropdown closed automatically
      expect(provider.selectedMode, 'Nozzle 3');
      expect(find.text('Ali Nozzle 3'), findsOneWidget);
      expect(find.text('Nozzle 4'), findsNothing);

      provider.dispose();
    });

    testWidgets('SourceSelectorDropdown shows Meter label when meter mode is selected and never Select Nozzle', (tester) async {
      PrimarySourceMode selectedMode = PrimarySourceMode.meter;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: SourceSelectorDropdown(
                selected: selectedMode,
                onChanged: (mode) => selectedMode = mode,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In Meter mode, pill displays 'Meter' and never 'Select Nozzle'
      expect(find.text('Meter'), findsOneWidget);
      expect(find.text('Select Nozzle'), findsNothing);
    });
  });
}
