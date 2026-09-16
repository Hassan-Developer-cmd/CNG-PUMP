import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Reusable service that permanently embeds a professional, clear date & time
/// timestamp into image pixels.
class ImageTimestampService {
  ImageTimestampService._();

  /// Embeds date and time onto [sourceFile] and returns a new [File] containing
  /// the stamped image. If processing fails, falls back to returning [sourceFile].
  static Future<File> addTimestamp(
    File sourceFile, {
    DateTime? capturedAt,
  }) async {
    try {
      if (!await sourceFile.exists()) {
        return sourceFile;
      }

      final Uint8List bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) {
        return sourceFile;
      }

      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return sourceFile;
      }

      // Ensure orientation from EXIF is applied before drawing text.
      image = img.bakeOrientation(image);

      final DateTime timestamp = capturedAt ?? DateTime.now();
      final String formattedTimestamp = formatTimestamp(timestamp);

      // Use largest crisp font for high quality rendering.
      final img.BitmapFont font = image.width >= 800
          ? img.arial48
          : image.width >= 400
              ? img.arial24
              : img.arial14;

      // Measure text width and height on font.
      final int lineHeight = font.lineHeight;
      int textWidth = 0;
      for (final int codeUnit in formattedTimestamp.codeUnits) {
        final charInfo = font.characters[codeUnit];
        textWidth += charInfo?.xAdvance ?? (lineHeight * 0.55).round();
      }

      final int padX = (lineHeight * 0.35).round().clamp(6, 30);
      final int padY = (lineHeight * 0.25).round().clamp(4, 20);

      final int bannerW = textWidth + (padX * 2);
      final int bannerH = lineHeight + (padY * 2);

      // Render text banner onto a high-contrast canvas.
      final img.Image banner = img.Image(width: bannerW, height: bannerH);
      img.fillRect(
        banner,
        x1: 0,
        y1: 0,
        x2: bannerW - 1,
        y2: bannerH - 1,
        color: img.ColorRgba8(0, 0, 0, 210),
      );

      img.drawString(
        banner,
        formattedTimestamp,
        font: font,
        x: padX,
        y: padY,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Scale banner proportionally so it is clearly visible on any resolution.
      // We aim for roughly 45% of the image width (clamped).
      final int targetW = (image.width * 0.45).round().clamp(bannerW, image.width - 20);
      final int targetH = ((targetW / bannerW) * bannerH).round();

      final img.Image scaledBanner = (targetW == bannerW)
          ? banner
          : img.copyResize(
              banner,
              width: targetW,
              height: targetH,
              interpolation: img.Interpolation.linear,
            );

      // Position in the bottom-left area with safe margin.
      final int marginX = (image.width * 0.035).round().clamp(10, 60);
      final int marginY = (image.height * 0.045).round().clamp(10, 60);

      final int dstX = marginX;
      final int dstY = (image.height - targetH - marginY).clamp(0, image.height - targetH);

      img.compositeImage(
        image,
        scaledBanner,
        dstX: dstX,
        dstY: dstY,
      );

      // Encode image as JPEG with high quality.
      final List<int> encodedBytes = img.encodeJpg(image, quality: 95);

      final Directory tempDir = Directory.systemTemp;
      final String targetPath =
          '${tempDir.path}/timestamped_cng_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final File timestampedFile = File(targetPath);
      await timestampedFile.writeAsBytes(encodedBytes, flush: true);

      debugPrint('[ImageTimestampService] Embedded timestamp: $formattedTimestamp');
      return timestampedFile;
    } catch (e, st) {
      debugPrint('[ImageTimestampService] Error embedding timestamp: $e\n$st');
      return sourceFile;
    }
  }

  /// Formats a [DateTime] into "DD/MM/YYYY hh:mm:ss AM/PM".
  static String formatTimestamp(DateTime dateTime) {
    final int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String second = dateTime.second.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final int year = dateTime.year;

    return '$day/$month/$year $hour:$minute:$second $period';
  }
}
