import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/main.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/text_comparison_provider.dart';
import 'package:cng_pump/screens/camera_screen/camera_screen.dart';
import 'package:cng_pump/screens/comparing_result/comparing_result_screen.dart';
import 'package:cng_pump/utils/reading_parser.dart';
import 'package:cng_pump/widgets/camera/camera_control_bar.dart';
import 'package:provider/provider.dart';

void main() {
  group('ReadingParser Tests', () {
    test('Correctly parses numeric weights with commas and units', () {
      expect(ReadingParser.parseNumeric('2,104.50 KG'), equals(2104.50));
      expect(ReadingParser.parseNumeric('2103.15'), equals(2103.15));
      expect(ReadingParser.parseNumeric('105.80 kg'), equals(105.80));
      expect(ReadingParser.parseNumeric(''), isNull);
      expect(ReadingParser.parseNumeric('Not Provided'), isNull);
    });

    test('Formats weight cleanly with commas', () {
      expect(ReadingParser.formatWeight(2104.50), equals('2,104.50 KG'));
      expect(ReadingParser.formatWeight(null), equals('Not Provided'));
    });

    test('Calculates difference matching reference screenshots', () {
      final diff = ReadingParser.calculateDifference(
        digitalMachine: 2104.50,
        manualData: 2103.15,
        microMotion: 2105.80,
      );
      expect(diff, closeTo(1.35, 0.001));
    });

    test('Extracts full CNG meter readings including decimals', () {
      // Decimal readings from CNG pump meter displays
      expect(ReadingParser.extractMeterReading('52.38'), equals('52.38'));
      expect(ReadingParser.extractMeterReading('2104.50 KG'), equals('2104.50'));
      expect(ReadingParser.extractMeterReading('24.259'), equals('24.259'));
      expect(ReadingParser.extractMeterReading('120 KG'), equals('120'));
      expect(ReadingParser.extractMeterReading('2,104 KG'), equals('2104'));

      // Selects the most prominent reading (KG line wins over unlabelled number)
      final linesWithKg = ['This Sale', '2104.50 KG', '24.259', 'Gallons'];
      expect(
        ReadingParser.extractMeterReading(
          'This Sale\n2104.50 KG\n24.259\nGallons',
          recognizedLines: linesWithKg,
        ),
        equals('2104.50'),
      );

      // Without KG, picks the larger/longer number
      final linesNoKg = ['This Sale', '52.38', '24.259', 'Gallons'];
      final result = ReadingParser.extractMeterReading(
        'This Sale\n52.38\n24.259\nGallons',
        recognizedLines: linesNoKg,
      );
      expect(result, isNotNull);

      // Pure label lines return null
      expect(ReadingParser.extractMeterReading('Gallons'), isNull);
      expect(ReadingParser.extractMeterReading('This Sale'), isNull);
      expect(ReadingParser.extractMeterReading(''), isNull);
      expect(ReadingParser.extractMeterReading(null), isNull);
      expect(ReadingParser.extractMeterReading('//--!@#'), isNull);

      // Legacy alias still works
      expect(ReadingParser.extractValidInteger('120 KG'), equals('120'));

      // Multi-reading extraction returns all unique numbers in relevance order
      final allReadings = ReadingParser.extractAllMeterReadings([
        'This Sale',
        '52.38',
        '24.259',
        'Gallons',
      ]);
      expect(allReadings, contains('52.38'));
      expect(allReadings, contains('24.259'));
      expect(allReadings.length, equals(2));
    });
  });

  group('TextComparisonProvider Tests', () {
    test('Initializes with 4 CNG reading items', () {
      final provider = TextComparisonProvider();
      expect(provider.readingItems.length, equals(4));
      expect(provider.readingItems[0].title, equals('Digital Machine'));
      expect(provider.readingItems[1].title, equals('Manual Data'));
      expect(provider.readingItems[2].title, equals('Micro Motion'));
      expect(provider.readingItems[3].title, equals('Sui Gas'));
      expect(provider.readingItems[0].isRequired, isTrue);
      expect(provider.readingItems[3].isRequired, isFalse);
    });

    test('Sets confirmed reading properly', () {
      final provider = TextComparisonProvider();
      // Using a dummy file path for unit testing
      provider.setConfirmedReading(0, File('test.jpg'), '52.38');

      expect(provider.readingItems[0].extractedText, equals('52.38'));
      expect(provider.readingItems[0].numericValue, equals(52.38));
      expect(provider.readingItems[0].hasImage, isTrue);
      expect(provider.readingItems[0].isLoading, isFalse);
      expect(provider.readingItems[0].error, isNull);
    });

    test('Detects corruption when difference exceeds threshold of 1.0 KG', () {
      final provider = TextComparisonProvider();
      provider.setTextByType(CngReadingType.digitalMachine, '2,104.50 KG');
      provider.setTextByType(CngReadingType.manualData, '2,103.15 KG');
      provider.setTextByType(CngReadingType.microMotion, '2,105.80 KG');

      final result = provider.comparisonResult;
      expect(result.difference, closeTo(1.35, 0.001));
      expect(result.isCorruptionDetected, isTrue);
      expect(result.alertTitle, equals('Corruption Detected'));
    });

    test('Verifies readings when difference is within 1.0 KG threshold', () {
      final provider = TextComparisonProvider();
      provider.setTextByType(CngReadingType.digitalMachine, '2,104.50 KG');
      provider.setTextByType(CngReadingType.manualData, '2,104.00 KG');
      provider.setTextByType(CngReadingType.microMotion, '2,104.20 KG');

      final result = provider.comparisonResult;
      expect(result.difference, closeTo(0.50, 0.001));
      expect(result.isCorruptionDetected, isFalse);
      expect(result.alertTitle, equals('Readings Verified'));
    });
  });

  testWidgets('DashboardScreen smoke test displays CNG Hub with 4 cards and Ali header', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TextComparisonProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.text('CNG Hub'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Digital Machine'), findsOneWidget);
    expect(find.text('Manual Data'), findsOneWidget);
    expect(find.text('Micro Motion'), findsOneWidget);
    expect(find.text('Sui Gas'), findsOneWidget);
    expect(find.text('REQUIRED'), findsNWidgets(3));
    expect(find.text('OPTIONAL'), findsOneWidget);
    expect(find.text('Compare Data'), findsOneWidget);
  });

  testWidgets('ComparingResultScreen displays details matching reference screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = TextComparisonProvider();
    provider.setTextByType(CngReadingType.digitalMachine, '2,104.50 KG');
    provider.setTextByType(CngReadingType.manualData, '2,103.15 KG');
    provider.setTextByType(CngReadingType.microMotion, '2,105.80 KG');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: ComparingResultScreen(),
        ),
      ),
    );

    expect(find.text('Comparison Result'), findsOneWidget);
    expect(find.text('Corruption Detected'), findsOneWidget);
    expect(find.text('COMPARISON DETAILS'), findsOneWidget);
    expect(find.text('2,104.50 KG'), findsOneWidget);
    expect(find.text('2,103.15 KG'), findsOneWidget);
    expect(find.text('2,105.80 KG'), findsOneWidget);
    expect(find.text('Not Provided'), findsOneWidget);
    expect(find.text('1.35 KG'), findsOneWidget);
    expect(find.text('1 KG'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('CameraScreen displays title, close button and controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: CameraScreen(),
      ),
    );

    // Verify top bar elements and controls
    expect(find.text('Scan Meter'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(CameraControlBar), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
  });
}
