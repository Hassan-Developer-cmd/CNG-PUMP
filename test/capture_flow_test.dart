import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';

void main() {
  group('CaptureProvider - Meter and Nozzle', () {
    test('Meter shows VB1, VS1 and optional R Flow', () {
      final provider = CaptureProvider();

      expect(provider.primarySourceMode, PrimarySourceMode.meter);
      expect(provider.readingItems.map((e) => e.title), ['VB1', 'VS1', 'R Flow']);
      expect(provider.readingItems[0].isRequired, isTrue);
      expect(provider.readingItems[1].isRequired, isTrue);
      expect(provider.readingItems[2].isRequired, isFalse);
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
    });

    test('View Result requires only the two required pictures', () async {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);
      await provider.setImage(0, File('first.jpg'));
      expect(provider.canViewResult, isFalse);
      await provider.setImage(1, File('second.jpg'));
      expect(provider.canViewResult, isTrue);

      // The optional third picture is not required.
      expect(provider.readingItems[2].hasImage, isFalse);
    });

    test('Capture sequence does not allow the next required picture before the first', () async {
      final provider = CaptureProvider();

      await provider.setImage(1, File('second.jpg'));
      expect(provider.readingItems[1].hasImage, isFalse);
      expect(provider.nextCaptureIndex, 0);
    });

    test('Timer starts after first required picture', () async {
      final provider = CaptureProvider();
      await provider.setImage(0, File('first.jpg'));

      expect(provider.timerActive, isTrue);
      expect(provider.remainingSeconds, 120);
      expect(provider.nextCaptureIndex, 1);
      provider.dispose();
    });
  });
}
