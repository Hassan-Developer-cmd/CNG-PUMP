import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';

void main() {
  group('Capture flow', () {
    test('Input Data is optional for a required picture item', () {
      final item = CngReadingItem(
        type: CngReadingType.digitalMachine,
        title: 'Digital Machine',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      item.image = File('digital_machine.jpg');

      expect(item.hasImage, isTrue);
      expect(item.hasInputData, isFalse);
      expect(item.isComplete, isTrue);
    });

    test('Required pictures, not Input Data, enable the result', () async {
      final provider = CaptureProvider();

      expect(provider.canViewResult, isFalse);

      await provider.setImage(0, File('digital_machine.jpg'));
      expect(provider.canViewResult, isFalse);

      await provider.setImage(1, File('manual_data.jpg'));

      // No Input Data has been entered, but both required pictures exist.
      expect(provider.readingItems[0].inputData, isEmpty);
      expect(provider.readingItems[1].inputData, isEmpty);
      expect(provider.requiredPicturesProvided, isTrue);
      expect(provider.canViewResult, isTrue);
    });

    test('Optional Input Data can still be stored', () {
      final provider = CaptureProvider();

      provider.setInputDataByType(
        CngReadingType.digitalMachine,
        '2104.50 KG',
      );

      expect(
        provider.getItemByType(CngReadingType.digitalMachine).inputData,
        equals('2104.50 KG'),
      );
    });
  });
}
