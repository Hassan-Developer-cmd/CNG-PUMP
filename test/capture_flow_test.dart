import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/services/image_timestamp_service.dart';
import 'package:cng_pump/widgets/shared_widgets/exit_confirmation_dialog.dart';

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

    test('Nozzle shows Digital Machine, Counter and optional Micro Motion', () {
      final provider = CaptureProvider();

      provider.setPrimarySourceMode(PrimarySourceMode.nozzle);

      expect(provider.readingItems.map((e) => e.title), [
        'Digital Machine',
        'Counter',
        'Micro Motion',
      ]);

      expect(provider.readingItems[0].isRequired, isTrue);

      expect(provider.readingItems[1].isRequired, isTrue);

      expect(provider.readingItems[2].isRequired, isFalse);

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
      'Capture sequence does not allow the next required picture before the first',
      () async {
        final provider = CaptureProvider();

        await provider.setImage(1, File('second.jpg'), testDateTime);

        expect(provider.readingItems[1].hasImage, isFalse);

        expect(provider.readingItems[1].capturedAt, isNull);

        expect(provider.nextCaptureIndex, 0);

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
}
