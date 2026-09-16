import 'dart:io';

class CaptureHistoryItem {
  final DateTime dateTime;
  final List<CapturedImage> images;

  CaptureHistoryItem({
    required this.dateTime,
    required this.images,
  });

  String get formattedDateTime {
    final d = dateTime;
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '$hour:$minute:$second $period';
  }
}

class CapturedImage {
  final String label;
  final File image;
  final DateTime capturedAt;

  CapturedImage({
    required this.label,
    required this.image,
    required this.capturedAt,
  });

  String get formattedCapturedAt {
    final d = capturedAt;

    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '$hour:$minute:$second $period';
  }
}