import 'dart:io';

class CaptureHistoryItem {
  final String id;
  final String stationName;
  final String operatorName;
  final DateTime dateTime;
  final List<CapturedImage> images;
  final String? modeName;
  final bool hasCorruption;
  final String statusText;
  final Map<String, String> sources;
  final String difference;
  final String threshold;

  static int _idCounter = 0;

  CaptureHistoryItem({
    String? id,
    String? stationName,
    String? operatorName,
    required this.dateTime,
    required this.images,
    this.modeName,
    this.hasCorruption = false,
    String? statusText,
    Map<String, String>? sources,
    this.difference = '+0.00 KG',
    this.threshold = '1.00 KG',
  })  : id = id ?? 'aud_${dateTime.microsecondsSinceEpoch}_${++_idCounter}',
        stationName = stationName ?? '',
        operatorName = operatorName ?? '',
        statusText = statusText ?? (hasCorruption ? 'CORRUPTION DETECTED' : 'IN-SYNC (0.00 KG)'),
        sources = sources ?? const {};

  factory CaptureHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['startedAt'] as String? ??
        json['createdAt'] as String? ??
        json['dateTime'] as String? ??
        json['timestamp'] as String?;
    final dateTime = rawDate != null
        ? DateTime.tryParse(rawDate) ?? DateTime.now()
        : DateTime.now();

    final hasCorr = json['hasCorruption'] as bool? ?? false;

    // Resolve mode name from modeName, mode, or captureType + nozzleNumber
    String? modeName = json['modeName'] as String? ?? json['mode'] as String?;
    if (modeName == null) {
      final captureType = (json['captureType'] as String?)?.toLowerCase();
      final nozzleNum = json['nozzleNumber'];
      if (captureType == 'meter') {
        modeName = 'Meter';
      } else if (captureType == 'nozzle') {
        modeName = nozzleNum != null ? 'Nozzle $nozzleNum' : 'Nozzle 1';
      }
    }

    // Resolve station name
    String stationName = json['stationName'] as String? ?? '';
    if (stationName.isEmpty) {
      if (json['station'] is Map) {
        stationName = (json['station']['name'] ?? json['station']['stationName'] ?? '') as String;
      } else if (json['station'] is String) {
        stationName = json['station'] as String;
      } else if (json['pump'] is Map) {
        stationName = (json['pump']['name'] ?? '') as String;
      }
    }

    // Resolve operator name
    String operatorName = json['operatorName'] as String? ?? '';
    if (operatorName.isEmpty) {
      if (json['operator'] is Map) {
        operatorName = (json['operator']['name'] ?? '') as String;
      } else if (json['operator'] is String) {
        operatorName = json['operator'] as String;
      } else if (json['user'] is Map) {
        operatorName = (json['user']['name'] ?? '') as String;
      }
    }

    // Resolve status text
    String? statusText = json['statusText'] as String?;
    if (statusText == null) {
      final status = (json['status'] as String?)?.toLowerCase();
      if (status == 'completed') {
        statusText = 'COMPLETED';
      } else if (status == 'in_progress') {
        statusText = 'IN PROGRESS';
      } else {
        statusText = hasCorr ? 'CORRUPTION DETECTED' : 'IN-SYNC (0.00 KG)';
      }
    }

    final rawImagesList = (json['images'] as List<dynamic>?) ??
        (json['uploadedImage'] as List<dynamic>?) ??
        (json['uploadedImages'] as List<dynamic>?);

    return CaptureHistoryItem(
      id: json['id'] as String? ??
          json['_id'] as String? ??
          'aud_${dateTime.millisecondsSinceEpoch}',
      stationName: stationName,
      operatorName: operatorName,
      dateTime: dateTime,
      images: rawImagesList
              ?.map((e) => CapturedImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modeName: modeName,
      hasCorruption: hasCorr,
      statusText: statusText,
      sources: (json['sources'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      difference: json['difference'] as String? ?? (hasCorr ? '-1.35 KG' : '+0.00 KG'),
      threshold: json['threshold'] as String? ?? '1.00 KG',
    );
  }

  List<String> get imageUrls => images
      .map((e) => e.imageUrl ?? '')
      .where((url) => url.isNotEmpty)
      .toList();

  List<String> get localPaths => images
      .map((e) => e.image.path)
      .where((path) => path.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationName': stationName,
      'operatorName': operatorName,
      'dateTime': dateTime.toIso8601String(),
      'images': images.map((e) => e.toJson()).toList(),
      'modeName': modeName,
      'hasCorruption': hasCorruption,
      'statusText': statusText,
      'sources': sources,
      'difference': difference,
      'threshold': threshold,
      'imageUrls': imageUrls,
      'localPaths': localPaths,
    };
  }

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
  final String? imageUrl;

  CapturedImage({
    required this.label,
    required this.image,
    required this.capturedAt,
    this.imageUrl,
  });

  factory CapturedImage.fromJson(Map<String, dynamic> json) {
    final imageType = json['imageType'] as String?;
    String rawLabel = json['label'] as String? ?? imageType ?? 'Image';
    if (rawLabel == 'vb1') {
      rawLabel = 'VB1';
    } else if (rawLabel == 'vs1') {
      rawLabel = 'VS1';
    } else if (rawLabel == 'digitalMachine') {
      rawLabel = 'Digital Machine';
    } else if (rawLabel == 'counter') {
      rawLabel = 'Counter';
    }

    final dateStr = json['captureAt'] as String? ??
        json['capturedAt'] as String? ??
        json['timestamp'] as String?;

    return CapturedImage(
      label: rawLabel,
      image: File(json['imagePath'] as String? ?? ''),
      capturedAt: dateStr != null
          ? DateTime.tryParse(dateStr) ?? DateTime.now()
          : DateTime.now(),
      imageUrl: json['imageUrl'] as String? ?? json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'imagePath': image.path,
      'capturedAt': capturedAt.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

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