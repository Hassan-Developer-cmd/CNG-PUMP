import 'dart:io';
import 'package:http_parser/http_parser.dart';

import '../constants/api_endpoints.dart';
import '../models/audit_config_model.dart';
import '../models/capture_history_item.dart';
import '../models/capture_upload_result.dart';
import '../models/comparison_history_record.dart';
import '../models/station_history_item.dart';
import '../services/api/api_client.dart';
import '../services/api/api_exception.dart';
import '../services/api/auth_storage.dart';

/// Maps card identifier and active mode to backend contract `imageType` value.
///
/// Backend strictly expects lowercase and specific camelCase enum strings for the text field `imageType`:
/// - If mode is "Meter":
///   - For VB1 card -> `imageType` must be `"vb1"`
///   - For VS1 card -> `imageType` must be `"vs1"`
/// - If mode is Nozzle (Nozzle 1, Nozzle 2, Nozzle 3, Nozzle 4):
///   - For Digital Machine / First card -> `imageType` must be `"digitalMachine"`
///   - For Counter / Second card -> `imageType` must be `"counter"`
String getBackendImageType(String cardId, String mode) {
  final cleanId = cardId.toLowerCase().trim();
  final cleanMode = mode.toLowerCase().trim();

  // Mode: Meter -> "vb1" | "vs1" | "rflow"
  if (cleanMode.contains('meter')) {
    if (cleanId.contains('vb1')) return 'vb1';
    if (cleanId.contains('vs1')) return 'vs1';
    if (cleanId.contains('rflow') || cleanId.contains('r_flow') || cleanId.contains('r flow')) return 'rflow';
  }

  // Mode: Nozzle -> "digitalMachine" | "counter" | "microMotion"
  if (cleanMode.contains('nozzle')) {
    if (cleanId.replaceAll(' ', '').contains('micromotion') || cleanId.contains('motion')) return 'microMotion';
    if (cleanId.contains('counter')) return 'counter';
    if (cleanId.contains('digital') ||
        cleanId.contains('machine') ||
        cleanId.contains('meter') ||
        cleanId.contains('nozzle') ||
        cleanId == 'first' ||
        cleanId == '1') {
      return 'digitalMachine';
    }
  }

  // General fallbacks across modes
  if (cleanId.contains('vb1')) return 'vb1';
  if (cleanId.contains('vs1')) return 'vs1';
  if (cleanId.contains('rflow') || cleanId.contains('r_flow') || cleanId.contains('r flow')) return 'rflow';
  if (cleanId.replaceAll(' ', '').contains('micromotion') || cleanId.contains('motion')) return 'microMotion';
  if (cleanId.contains('counter')) return 'counter';
  if (cleanId.contains('digital') || cleanId.contains('machine')) return 'digitalMachine';

  return cleanId;
}

abstract class AuditRepository {
  AuditConfigModel get initialAuditConfig;
  List<StationHistoryItem> get initialStationRecords;
  List<ComparisonHistoryRecord> get initialComparisonRecords;

  Future<AuditConfigModel> getAuditConfig();
  Future<List<CaptureHistoryItem>> getHistoryRecords();
  Future<void> saveHistoryRecord(CaptureHistoryItem record);
  Future<List<StationHistoryItem>> getStationRecords();
  Future<List<ComparisonHistoryRecord>> getComparisonRecords();

  /// Uploads a single captured image to `/api/v1/capture/captureImage`.
  /// [mode] — active audit mode label, e.g. "Meter", "Nozzle 1".
  /// [readingType] — card identifier, e.g. "meter", "counter", "micro_motion".
  /// [imageType] — exact backend contract value, e.g. "vb1", "vs1", "digitalMachine", "counter".
  /// [readingValue] — optional numeric reading from OCR / manual input.
  /// [imageFile] — the real watermarked file from device storage.
  Future<CaptureUploadResult> uploadCapturedImage({
    required String mode,
    required String readingType,
    String? imageType,
    required File imageFile,
    String? readingValue,
    DateTime? timestamp,
  });

  /// Marks a capture session as complete via `POST /api/v1/capture/complete/:id`.
  ///
  /// [sessionId]   — the local or server-assigned ID of the session to complete.
  /// [mode]        — audit mode string, e.g. "Meter" or "Nozzle 1".
  /// [imageIds]    — server-side image IDs returned from individual uploads.
  /// [imageUrls]   — server-side image URLs returned from individual uploads.
  /// [statusText]  — final audit verdict string.
  /// [hasCorruption] — whether a discrepancy was flagged.
  Future<Map<String, dynamic>> completeAuditSession({
    required String sessionId,
    String? mode,
    List<CapturedImage>? capturedImages,
    File? imageFile,
    String? imageType,
    List<String>? imageIds,
    List<String>? imageUrls,
    String? statusText,
    bool hasCorruption = false,
    String? difference,
    String? threshold,
    String? stationName,
    String? operatorName,
  });
}

/// Production-ready Remote API Audit Repository
class RemoteAuditRepository implements AuditRepository {
  final ApiClient _client;

  RemoteAuditRepository({ApiClient? client, String? baseUrl})
      : _client = client ?? ApiClient.instance;

  ApiClient get client => _client;

  @override
  AuditConfigModel get initialAuditConfig => const AuditConfigModel();

  @override
  List<StationHistoryItem> get initialStationRecords => const [];

  @override
  List<ComparisonHistoryRecord> get initialComparisonRecords => const [];

  @override
  Future<AuditConfigModel> getAuditConfig() async {
    try {
      final response = await _client.get(ApiEndpoints.auditConfig);
      if (response is Map<String, dynamic>) {
        final json = response['data'] is Map ? response['data'] : response;
        return AuditConfigModel.fromJson(json as Map<String, dynamic>);
      }
    } catch (_) {}
    return const AuditConfigModel();
  }

  @override
  Future<List<CaptureHistoryItem>> getHistoryRecords() async {
    // 1. Ensure token is loaded if present in AuthStorage
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      try {
        final token = await AuthStorage.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _client.setAuthToken(token);
        }
      } catch (_) {}
    }

    dynamic response;
    try {
      response = await _client.get(ApiEndpoints.captureHistory);
    } catch (_) {
      try {
        response = await _client.get(ApiEndpoints.audits);
      } catch (e) {
        rethrow;
      }
    }

    final List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map) {
      if (response['captures'] is List) {
        list = response['captures'] as List;
      } else if (response['data'] is List) {
        list = response['data'] as List;
      } else if (response['history'] is List) {
        list = response['history'] as List;
      } else if (response['audits'] is List) {
        list = response['audits'] as List;
      } else {
        list = const [];
      }
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => CaptureHistoryItem.fromJson(json))
        .toList();
  }

  @override
  Future<void> saveHistoryRecord(CaptureHistoryItem record) async {
    // Check if we have local image files to upload via multipart
    final filesMap = <String, File>{};
    for (int i = 0; i < record.images.length; i++) {
      final img = record.images[i];
      if (img.image.path.isNotEmpty) {
        final file = File(img.image.path);
        if (file.existsSync()) {
          final fieldKey = img.label.toLowerCase().replaceAll(' ', '_');
          filesMap[fieldKey.isEmpty ? 'image_$i' : fieldKey] = file;
        }
      }
    }

    if (filesMap.isNotEmpty) {
      // Multipart form upload
      final fields = <String, String>{
        'stationName': record.stationName,
        'operatorName': record.operatorName,
        'dateTime': record.dateTime.toIso8601String(),
        'hasCorruption': record.hasCorruption.toString(),
        'statusText': record.statusText,
        'difference': record.difference,
        'threshold': record.threshold,
        if (record.modeName != null) 'modeName': record.modeName!,
      };

      for (final entry in record.sources.entries) {
        fields['source_${entry.key}'] = entry.value;
      }

      await _client.multipartPost(
        ApiEndpoints.audits,
        fields: fields,
        files: filesMap,
      );
    } else {
      // JSON upload
      await _client.post(
        ApiEndpoints.audits,
        body: record.toJson(),
      );
    }
  }

  @override
  Future<List<StationHistoryItem>> getStationRecords() async {
    final histories = await getHistoryRecords();
    return histories.map((h) => StationHistoryItem.fromCaptureHistoryItem(h)).toList();
  }

  @override
  Future<List<ComparisonHistoryRecord>> getComparisonRecords() async {
    return const [];
  }

  @override
  Future<CaptureUploadResult> uploadCapturedImage({
    required String mode,
    required String readingType,
    String? imageType,
    required File imageFile,
    String? readingValue,
    DateTime? timestamp,
  }) async {
    // 1. Ensure token is loaded if present in AuthStorage
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      try {
        final token = await AuthStorage.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _client.setAuthToken(token);
        }
      } catch (_) {}
    }

    final ts = (timestamp ?? DateTime.now()).toIso8601String();
    // Resolve exact backend enum value (e.g. vb1, vs1, digitalMachine, counter, microMotion)
    String mappedType = imageType ?? getBackendImageType(readingType, mode);
    if (mappedType.toLowerCase().replaceAll(' ', '').contains('micromotion') ||
        mappedType.toLowerCase().contains('motion')) {
      mappedType = 'microMotion';
    } else if (mappedType.toLowerCase().replaceAll(' ', '').contains('digitalmachine') ||
        mappedType.toLowerCase().contains('digital')) {
      mappedType = 'digitalMachine';
    } else if (mappedType.toLowerCase().contains('counter')) {
      mappedType = 'counter';
    }

    final cleanMode = mode.toLowerCase();
    final isNozzle = cleanMode.contains('nozzle');
    final captureType = isNozzle ? 'nozzle' : 'meter';
    String? nozzleNumber;
    if (isNozzle) {
      final match = RegExp(r'\d+').firstMatch(mode);
      nozzleNumber = match != null ? match.group(0) : '1';
    }

    final fields = <String, String>{
      'imageType': mappedType,
      'captureType': captureType,
      if (nozzleNumber != null) 'nozzleNumber': nozzleNumber,
      'mode': mode,
      'readingType': mappedType,
      'timestamp': ts,
      if (readingValue != null && readingValue.trim().isNotEmpty)
        'readingValue': readingValue.trim(),
    };

    try {
      final response = await _client.multipartPost(
        ApiEndpoints.captureImage,
        fields: fields,
        files: {'image': imageFile},
        contentType: MediaType('image', 'jpeg'),
      );

      final jsonMap =
          response is Map<String, dynamic> ? response : <String, dynamic>{};
      return CaptureUploadResult.fromJson(jsonMap);
    } on ApiException catch (e) {
      String message = e.message;
      if (e.responseData is Map && e.responseData['message'] != null) {
        message = e.responseData['message'].toString();
      }
      return CaptureUploadResult(
        success: false,
        message: message,
      );
    } catch (e) {
      return CaptureUploadResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> completeAuditSession({
    required String sessionId,
    String? mode,
    List<CapturedImage>? capturedImages,
    File? imageFile,
    String? imageType,
    List<String>? imageIds,
    List<String>? imageUrls,
    String? statusText,
    bool hasCorruption = false,
    String? difference,
    String? threshold,
    String? stationName,
    String? operatorName,
  }) async {
    // 1. Ensure token is loaded if present in AuthStorage
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      try {
        final token = await AuthStorage.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _client.setAuthToken(token);
        }
      } catch (_) {}
    }

    // 2. Trigger POST to /api/v1/capture/complete/$captureId with empty body and JSON headers
    final endpoint = ApiEndpoints.captureComplete(sessionId.trim());
    final response = await _client.post(endpoint);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true, 'data': response};
  }
}

/// Fallback Mock Audit Repository without preset static audit sessions
class MockAuditRepository implements AuditRepository {
  final AuditConfigModel _auditConfig = const AuditConfigModel();
  final List<CaptureHistoryItem> _historyRecords = [];
  final List<StationHistoryItem> _stationRecords = [];
  final List<ComparisonHistoryRecord> _comparisonRecords = [];

  @override
  AuditConfigModel get initialAuditConfig => _auditConfig;

  @override
  List<StationHistoryItem> get initialStationRecords => const [];

  @override
  List<ComparisonHistoryRecord> get initialComparisonRecords => const [];

  @override
  Future<AuditConfigModel> getAuditConfig() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _auditConfig;
  }

  @override
  Future<List<CaptureHistoryItem>> getHistoryRecords() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_historyRecords);
  }

  @override
  Future<void> saveHistoryRecord(CaptureHistoryItem record) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _historyRecords.removeWhere((r) => r.id == record.id);
    _historyRecords.insert(0, record);

    _stationRecords.removeWhere((s) => s.id == record.id);
    _stationRecords.insert(0, StationHistoryItem.fromCaptureHistoryItem(record));
  }

  @override
  Future<CaptureUploadResult> uploadCapturedImage({
    required String mode,
    required String readingType,
    String? imageType,
    required File imageFile,
    String? readingValue,
    DateTime? timestamp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    // Mock: return a fake successful result with a stub URL.
    return CaptureUploadResult(
      success: true,
      imageUrl: 'mock://uploads/$readingType/${DateTime.now().millisecondsSinceEpoch}.jpg',
      imageId: 'mock_${readingType}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<List<StationHistoryItem>> getStationRecords() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_stationRecords);
  }

  @override
  Future<List<ComparisonHistoryRecord>> getComparisonRecords() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_comparisonRecords);
  }

  @override
  Future<Map<String, dynamic>> completeAuditSession({
    required String sessionId,
    String? mode,
    List<CapturedImage>? capturedImages,
    File? imageFile,
    String? imageType,
    List<String>? imageIds,
    List<String>? imageUrls,
    String? statusText,
    bool hasCorruption = false,
    String? difference,
    String? threshold,
    String? stationName,
    String? operatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    // Mock: simulate a successful completion.
    return {
      'success': true,
      'sessionId': sessionId,
      'status': statusText ?? 'IN_SYNC',
      'hasCorruption': hasCorruption,
      if (difference != null) 'difference': difference,
      'completedAt': DateTime.now().toIso8601String(),
    };
  }
}
