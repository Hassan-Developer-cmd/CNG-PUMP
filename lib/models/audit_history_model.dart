import 'dart:io';
import '../../constants/api_constants.dart';
import 'capture_history_item.dart';

/// Single image object within an audit session from MongoDB.
class AuditHistoryImage {
  final String imageType;
  final String imageUrl;
  final String label;
  final DateTime timestamp;

  const AuditHistoryImage({
    required this.imageType,
    required this.imageUrl,
    required this.label,
    required this.timestamp,
  });

  factory AuditHistoryImage.fromJson(dynamic json) {
    if (json is String) {
      final normalized = normalizeImageUrl(json);
      return AuditHistoryImage(
        imageType: 'image',
        imageUrl: normalized,
        label: 'Image',
        timestamp: DateTime.now(),
      );
    }

    if (json is Map<String, dynamic>) {
      final type = json['imageType'] as String? ??
          json['type'] as String? ??
          json['label'] as String? ??
          'image';

      final rawUrl = json['imageUrl'] as String? ??
          json['url'] as String? ??
          json['path'] as String? ??
          json['imagePath'] as String? ??
          '';

      final tsStr = json['timestamp'] as String? ??
          json['capturedAt'] as String? ??
          json['createdAt'] as String?;
      final ts = tsStr != null
          ? DateTime.tryParse(tsStr) ?? DateTime.now()
          : DateTime.now();

      final label = json['label'] as String? ?? formatImageTypeLabel(type);

      return AuditHistoryImage(
        imageType: type,
        imageUrl: normalizeImageUrl(rawUrl),
        label: label,
        timestamp: ts,
      );
    }

    return AuditHistoryImage(
      imageType: 'image',
      imageUrl: '',
      label: 'Image',
      timestamp: DateTime.now(),
    );
  }

  /// Normalizes any relative or partial image URL to a full backend URL.
  /// (e.g. `/uploads/123.jpg` -> `http://192.168.1.8:5000/uploads/123.jpg`)
  static String normalizeImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = ApiConstants.baseUrl.isNotEmpty
        ? (ApiConstants.baseUrl.endsWith('/')
            ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
            : ApiConstants.baseUrl)
        : 'http://192.168.1.8:5000';

    return '$base${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  String get path => imageUrl;
  String get url => imageUrl;

  /// Human-friendly label for raw imageType backend values
  static String formatImageTypeLabel(String type) {
    final clean = type.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (clean) {
      case 'vb1':
        return 'VB1';
      case 'vs1':
        return 'VS1';
      case 'rflow':
        return 'R Flow';
      case 'digitalmachine':
      case 'meter':
        return 'Digital Machine';
      case 'counter':
        return 'Counter';
      case 'micromotion':
        return 'Micro Motion';
      default:
        return type.isNotEmpty ? type : 'Photo';
    }
  }

  CapturedImage toCapturedImage() {
    return CapturedImage(
      label: label,
      image: File(''),
      imageUrl: imageUrl,
      capturedAt: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageType': imageType,
        'imageUrl': imageUrl,
        'label': label,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Represents a persistent MongoDB audit session record.
class AuditHistoryModel {
  final String id;
  final String stationName;
  final String? stationId;
  final String operatorName;
  final String? operatorId;
  final String mode; // "meter" or "nozzle"
  final String? nozzleNumber;
  final DateTime createdAt;
  final List<AuditHistoryImage> images;
  final String? status;
  final String difference;
  final String threshold;
  final bool hasCorruption;

  const AuditHistoryModel({
    required this.id,
    required this.stationName,
    this.stationId,
    required this.operatorName,
    this.operatorId,
    required this.mode,
    this.nozzleNumber,
    required this.createdAt,
    required this.images,
    this.status,
    this.difference = '0.00 KG',
    this.threshold = '1.00 KG',
    this.hasCorruption = false,
  });

  factory AuditHistoryModel.fromJson(dynamic rawJson) {
    final Map<String, dynamic> json = rawJson is Map<String, dynamic>
        ? rawJson
        : (rawJson is Map
            ? rawJson.map((k, v) => MapEntry(k.toString(), v))
            : <String, dynamic>{});

    // 1. Resolve ID (_id or id)
    final id = (json['id'] ?? json['_id'])?.toString() ??
        'aud_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Resolve Station Details
    String stationName = json['stationName'] as String? ?? '';
    String? stationId = json['stationId'] as String?;
    if (stationName.isEmpty && json['station'] != null) {
      if (json['station'] is Map) {
        final stMap = json['station'] as Map<String, dynamic>;
        stationName = (stMap['name'] ?? stMap['stationName'] ?? '') as String;
        stationId ??= (stMap['id'] ?? stMap['_id']) as String?;
      } else if (json['station'] is String) {
        stationName = json['station'] as String;
      }
    }
    if (stationName.isEmpty && json['pump'] != null) {
      if (json['pump'] is Map) {
        final pumpMap = json['pump'] as Map<String, dynamic>;
        stationName = (pumpMap['name'] ?? '') as String;
        stationId ??= (pumpMap['id'] ?? pumpMap['_id']) as String?;
      } else if (json['pump'] is String) {
        stationName = json['pump'] as String;
      }
    }
    if (stationName.isEmpty) {
      stationName = 'CNG Station';
    }

    // 3. Resolve Operator Details
    String operatorName = json['operatorName'] as String? ?? '';
    String? operatorId = json['operatorId'] as String?;
    if (operatorName.isEmpty && json['operator'] != null) {
      if (json['operator'] is Map) {
        final opMap = json['operator'] as Map<String, dynamic>;
        operatorName = (opMap['name'] ?? '') as String;
        operatorId ??= (opMap['id'] ?? opMap['_id']) as String?;
      } else if (json['operator'] is String) {
        operatorName = json['operator'] as String;
      }
    }
    if (operatorName.isEmpty && json['user'] != null) {
      if (json['user'] is Map) {
        final userMap = json['user'] as Map<String, dynamic>;
        operatorName = (userMap['name'] ?? '') as String;
        operatorId ??= (userMap['id'] ?? userMap['_id']) as String?;
      } else if (json['user'] is String) {
        operatorName = json['user'] as String;
      }
    }
    if (operatorName.isEmpty) {
      operatorName = 'Operator';
    }

    // 4. Resolve Mode ("meter" or "nozzle") & Nozzle Number
    String mode = json['mode'] as String? ??
        json['captureType'] as String? ??
        json['modeName'] as String? ??
        'meter';
    mode = mode.toLowerCase();
    if (mode.contains('nozzle')) {
      mode = 'nozzle';
    } else {
      mode = 'meter';
    }

    String? nozzleNumber = json['nozzleNumber']?.toString();
    if (nozzleNumber == null && mode == 'nozzle') {
      final rawMode = (json['mode'] ?? json['modeName'] ?? '').toString();
      final match = RegExp(r'\d+').firstMatch(rawMode);
      if (match != null) {
        nozzleNumber = match.group(0);
      }
    }

    // 5. Resolve CreatedAt / Timestamp
    final rawDate = json['createdAt'] as String? ??
        json['timestamp'] as String? ??
        json['startedAt'] as String? ??
        json['dateTime'] as String?;
    final createdAt = rawDate != null
        ? DateTime.tryParse(rawDate) ?? DateTime.now()
        : DateTime.now();

    // 6. Resolve Images List
    final rawImages = json['images'] as List<dynamic>? ??
        json['uploadedImages'] as List<dynamic>? ??
        json['uploadedImage'] as List<dynamic>? ??
        json['photos'] as List<dynamic>? ??
        [];

    final images = rawImages.map((e) => AuditHistoryImage.fromJson(e)).toList();

    // 7. Resolve Status & Corruption
    final hasCorr = json['hasCorruption'] as bool? ?? false;
    final status = json['status'] as String? ?? json['statusText'] as String?;
    final difference = json['difference'] as String? ?? (hasCorr ? '-1.35 KG' : '0.00 KG');
    final threshold = json['threshold'] as String? ?? '1.00 KG';

    return AuditHistoryModel(
      id: id,
      stationName: stationName,
      stationId: stationId,
      operatorName: operatorName,
      operatorId: operatorId,
      mode: mode,
      nozzleNumber: nozzleNumber,
      createdAt: createdAt,
      images: images,
      status: status,
      difference: difference,
      threshold: threshold,
      hasCorruption: hasCorr,
    );
  }

  /// Formats mode display string (e.g. "Meter", "Nozzle 1", "Nozzle 2", "Nozzle")
  String get formattedModeName {
    if (mode.toLowerCase() == 'meter') return 'Meter';
    if (nozzleNumber != null && nozzleNumber!.isNotEmpty) {
      return 'Nozzle $nozzleNumber';
    }
    if (mode.toLowerCase() == 'nozzle') return 'Nozzle';
    return mode;
  }

  /// Formatted date and time string: DD/MM/YYYY  HH:MM:SS AM/PM
  String get formattedDateTime {
    final d = createdAt;
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '$hour:$minute:$second $period';
  }

  /// Converts this MongoDB audit model to a [CaptureHistoryItem] for backward compatibility
  CaptureHistoryItem toCaptureHistoryItem() {
    return CaptureHistoryItem(
      id: id,
      stationName: stationName,
      operatorName: operatorName,
      dateTime: createdAt,
      images: images.map((img) => img.toCapturedImage()).toList(),
      modeName: formattedModeName,
      hasCorruption: hasCorruption,
      statusText: status ?? (hasCorruption ? 'CORRUPTION DETECTED' : 'IN-SYNC ($difference)'),
      difference: difference,
      threshold: threshold,
    );
  }

  String get captureType => mode;

  /// Formatted mode details: "Meter Audit" or "Nozzle X Audit"
  String get formattedModeDetails {
    if (mode.toLowerCase() == 'meter') {
      return 'Meter Audit';
    }
    if (nozzleNumber != null && nozzleNumber!.isNotEmpty) {
      return 'Nozzle $nozzleNumber Audit';
    }
    return 'Nozzle Audit';
  }

  /// Formatted operator badge with ID if present: e.g. "adnangul (ID: ...)"
  String get formattedOperatorBadge {
    if (operatorId != null && operatorId!.isNotEmpty) {
      return '$operatorName (ID: $operatorId)';
    }
    return operatorName;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationName': stationName,
        if (stationId != null) 'stationId': stationId,
        'operatorName': operatorName,
        if (operatorId != null) 'operatorId': operatorId,
        'mode': mode,
        if (nozzleNumber != null) 'nozzleNumber': nozzleNumber,
        'createdAt': createdAt.toIso8601String(),
        'images': images.map((e) => e.toJson()).toList(),
        if (status != null) 'status': status,
        'difference': difference,
        'threshold': threshold,
        'hasCorruption': hasCorruption,
      };
}

/// Dynamic alias for AuditSessionModel matching backend API naming specification
typedef AuditSessionModel = AuditHistoryModel;
