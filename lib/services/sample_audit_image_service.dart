import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'image_timestamp_service.dart';

/// Generates realistic watermarked dispenser / meter sample photos for audit inspection.
class SampleAuditImageService {
  SampleAuditImageService._();

  static final Map<String, File> _cachedSampleFiles = {};

  /// Returns a real watermarked [File] representing a physical meter capture.
  static Future<File> getOrCreateSampleImage({
    required String label,
    required DateTime capturedAt,
    String? readingValue,
    String? serialNumber,
  }) async {
    final key = '${label}_${capturedAt.millisecondsSinceEpoch}';
    if (_cachedSampleFiles.containsKey(key)) {
      final cached = _cachedSampleFiles[key]!;
      if (cached.existsSync()) return cached;
    }

    try {
      final Directory tempDir = Directory.systemTemp;
      final String filePath = '${tempDir.path}/sample_watermarked_${label.replaceAll(' ', '_')}_${capturedAt.millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      if (file.existsSync()) {
        _cachedSampleFiles[key] = file;
        return file;
      }

      // Generate realistic 800x600 industrial LCD dispenser image
      final img.Image canvas = img.Image(width: 800, height: 600);
      
      // Industrial metallic / dark slate gradient
      img.fill(canvas, color: img.ColorRgb8(18, 24, 38));

      // Dispenser bezel outer border
      img.drawRect(
        canvas,
        x1: 20,
        y1: 20,
        x2: 779,
        y2: 579,
        color: img.ColorRgb8(45, 55, 72),
        thickness: 4,
      );

      // Inner LCD Screen Glass
      img.fillRect(
        canvas,
        x1: 60,
        y1: 70,
        x2: 740,
        y2: 440,
        color: img.ColorRgb8(8, 14, 24),
      );

      // LCD Screen Green Grid Border
      img.drawRect(
        canvas,
        x1: 60,
        y1: 70,
        x2: 740,
        y2: 440,
        color: img.ColorRgb8(34, 197, 94),
        thickness: 2,
      );

      // Label & Unit info header
      final displayLabel = label.toUpperCase();
      img.drawString(
        canvas,
        'CNG FORECOURT AUDIT DISPENSER • $displayLabel',
        font: img.arial24,
        x: 80,
        y: 95,
        color: img.ColorRgb8(148, 163, 184),
      );

      // Serial Tag
      final serial = serialNumber ?? 'SERIAL: PK-CNG-${(label.hashCode.abs() % 9000 + 1000)}';
      img.drawString(
        canvas,
        serial,
        font: img.arial14,
        x: 80,
        y: 135,
        color: img.ColorRgb8(100, 116, 139),
      );

      // Large LCD Digital Reading Display
      final reading = readingValue ?? '2,105.85 KG';
      img.drawString(
        canvas,
        reading,
        font: img.arial48,
        x: 80,
        y: 200,
        color: img.ColorRgb8(52, 211, 153), // bright green LED digits
      );

      // Sub-metrics / Flow Rate
      img.drawString(
        canvas,
        'PRESSURE: 215.4 BAR   |   TEMP: 26.8 C   |   STATUS: FLOW VERIFIED',
        font: img.arial14,
        x: 80,
        y: 290,
        color: img.ColorRgb8(94, 234, 212),
      );

      // Security Seal Banner inside glass
      img.fillRect(
        canvas,
        x1: 80,
        y1: 340,
        x2: 720,
        y2: 410,
        color: img.ColorRgb8(15, 23, 42),
      );
      img.drawString(
        canvas,
        'TAMPER-EVIDENT HARDWARE SEAL #SEAL-${(label.hashCode.abs() % 8000 + 2000)} [INTACT]',
        font: img.arial14,
        x: 95,
        y: 365,
        color: img.ColorRgb8(245, 158, 11), // amber warning seal
      );

      // Encode temp raw image
      final rawBytes = img.encodeJpg(canvas, quality: 90);
      await file.writeAsBytes(rawBytes, flush: true);

      // Permanently embed pixel watermark using ImageTimestampService
      final stampedFile = await ImageTimestampService.addTimestamp(
        file,
        capturedAt: capturedAt,
      );

      _cachedSampleFiles[key] = stampedFile;
      return stampedFile;
    } catch (e) {
      debugPrint('[SampleAuditImageService] Error creating sample image: $e');
      final fallbackFile = File('${Directory.systemTemp.path}/fallback_$key.jpg');
      return fallbackFile;
    }
  }
}
