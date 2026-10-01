import 'capture_history_item.dart';

class StationHistoryItem {
  final String id;
  final String stationName;
  final String location;
  final DateTime timestamp;
  final String timeDisplay;
  final bool isChecked;
  final String? imageUrl;
  final String operatorName;
  final String operatorId;
  final String auditMode;
  final bool hasCorruption;
  final String statusText;
  final String difference;
  final String threshold;
  final Map<String, String>? sources;
  final List<CapturedImage> images;

  const StationHistoryItem({
    required this.id,
    required this.stationName,
    required this.location,
    required this.timestamp,
    required this.timeDisplay,
    this.isChecked = true,
    this.imageUrl,
    this.operatorName = '',
    this.operatorId = '',
    this.auditMode = 'Meter',
    this.hasCorruption = false,
    this.statusText = 'IN-SYNC (0.00 KG)',
    this.difference = '+0.00 KG',
    this.threshold = '1.00 KG',
    this.sources,
    this.images = const [],
  });

  List<String> get imageUrls => images
      .map((e) => e.imageUrl ?? '')
      .where((url) => url.isNotEmpty)
      .toList();

  List<String> get localPaths => images
      .map((e) => e.image.path)
      .where((path) => path.isNotEmpty)
      .toList();

  CaptureHistoryItem toCaptureHistoryItem() {
    return CaptureHistoryItem(
      id: id,
      stationName: stationName,
      operatorName: operatorName,
      dateTime: timestamp,
      images: images,
      modeName: auditMode,
      hasCorruption: hasCorruption,
      statusText: statusText,
      sources: sources ?? const {},
      difference: difference,
      threshold: threshold,
    );
  }

  factory StationHistoryItem.fromCaptureHistoryItem(CaptureHistoryItem item) {
    return StationHistoryItem(
      id: item.id,
      stationName: item.stationName,
      location: 'Forecourt Station',
      timestamp: item.dateTime,
      timeDisplay: item.formattedDateTime,
      isChecked: !item.hasCorruption,
      operatorName: item.operatorName,
      operatorId: item.operatorName.contains('(')
          ? item.operatorName.split('(').last.replaceAll(')', '').trim()
          : item.operatorName,
      auditMode: item.modeName ?? 'Meter',
      hasCorruption: item.hasCorruption,
      statusText: item.statusText,
      difference: item.difference,
      threshold: item.threshold,
      sources: item.sources,
      images: item.images,
    );
  }

  factory StationHistoryItem.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now();

    final hasCorr = json['hasCorruption'] as bool? ??
        !(json['isChecked'] as bool? ?? true);
    final station = json['stationName'] as String? ?? '';

    final rawImages = (json['images'] as List<dynamic>?)
        ?.map((e) => CapturedImage.fromJson(e as Map<String, dynamic>))
        .toList();

    return StationHistoryItem(
      id: json['id'] as String? ?? '',
      stationName: station,
      location: json['location'] as String? ?? '',
      timestamp: timestamp,
      timeDisplay: json['timeDisplay'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? !hasCorr,
      imageUrl: json['imageUrl'] as String?,
      operatorName: json['operatorName'] as String? ?? '',
      operatorId: json['operatorId'] as String? ?? '',
      auditMode: json['auditMode'] as String? ??
          (json['modeName'] as String? ?? 'Meter'),
      hasCorruption: hasCorr,
      statusText: json['statusText'] as String? ??
          (hasCorr ? 'CORRUPTION DETECTED' : 'IN-SYNC (0.00 KG)'),
      difference: json['difference'] as String? ??
          (hasCorr ? '-1.35 KG' : '+0.00 KG'),
      threshold: json['threshold'] as String? ?? '1.00 KG',
      sources: (json['sources'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      images: rawImages ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationName': stationName,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'timeDisplay': timeDisplay,
      'isChecked': isChecked,
      'imageUrl': imageUrl,
      'operatorName': operatorName,
      'operatorId': operatorId,
      'auditMode': auditMode,
      'hasCorruption': hasCorruption,
      'statusText': statusText,
      'difference': difference,
      'threshold': threshold,
      'sources': sources,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}
