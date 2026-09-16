import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';

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

    test('Timer starts after first required picture', () async {
      final provider = CaptureProvider();

      await provider.setImage(0, File('first.jpg'), testDateTime);

      expect(provider.timerActive, isTrue);

      expect(provider.remainingSeconds, 120);

      expect(provider.nextCaptureIndex, 1);

      expect(provider.readingItems[0].capturedAt, equals(testDateTime));

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
}
