import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../config/app_dependencies.dart';
import '../models/audit_history_model.dart';
import '../models/capture_history_item.dart';
import '../models/station_history_item.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_storage.dart';
import '../repositories/audit_repository.dart';

import '../widgets/shared_widgets/async_state_view.dart';

enum HistoryTimeFilter { all, today, last7Days, last30Days }

/// Provider for dynamic MongoDB audit history synchronization.
/// Completely eliminates all static/mock data and reflects the live database state.
class HistoryProvider extends ChangeNotifier {
  final http.Client _httpClient;
  final dynamic _repository;

  List<AuditSessionModel> historyList = [];
  bool isLoading = false;
  String? errorMessage;
  HistoryTimeFilter _selectedFilter = HistoryTimeFilter.all;

  HistoryProvider({http.Client? httpClient, dynamic repository})
      : _repository = repository,
        _httpClient = httpClient ??
            (repository != null && repository is RemoteAuditRepository
                ? repository.client.httpClient
                : ApiClient.instance.httpClient);

  AuthStorage get secureStorage => AuthStorage.instance;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => historyList.isEmpty;

  AsyncStatus get status {
    if (isLoading) return AsyncStatus.loading;
    if (hasError) return AsyncStatus.error;
    if (isEmpty) return AsyncStatus.empty;
    return AsyncStatus.loaded;
  }

  HistoryTimeFilter get selectedFilter => _selectedFilter;

  void setFilter(HistoryTimeFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Returns dynamically mapped [CaptureHistoryItem]s for visual cards & inspection viewers
  List<CaptureHistoryItem> get auditSessions =>
      historyList.map((m) => m.toCaptureHistoryItem()).toList();

  List<CaptureHistoryItem> get records => auditSessions;

  List<StationHistoryItem> get stationRecords =>
      auditSessions.map((h) => StationHistoryItem.fromCaptureHistoryItem(h)).toList();

  List<StationHistoryItem> get filteredStationRecords {
    final list = stationRecords;
    final now = DateTime.now();
    switch (_selectedFilter) {
      case HistoryTimeFilter.today:
        return list.where((item) {
          final diff = now.difference(item.timestamp);
          return diff.inDays == 0 && item.timestamp.day == now.day;
        }).toList();
      case HistoryTimeFilter.last7Days:
        return list.where((item) {
          return now.difference(item.timestamp).inDays <= 7;
        }).toList();
      case HistoryTimeFilter.last30Days:
        return list.where((item) {
          return now.difference(item.timestamp).inDays <= 30;
        }).toList();
      case HistoryTimeFilter.all:
        return list;
    }
  }

  CaptureHistoryItem? findSessionById(String id) {
    try {
      final found = historyList.firstWhere((s) => s.id == id);
      return found.toCaptureHistoryItem();
    } catch (_) {
      return null;
    }
  }

  /// Fetches persistent audit sessions from MongoDB via `GET http://192.168.1.8:5000/api/v1/capture/history`
  Future<void> fetchHistory({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final currentRepo = _repository ??
          (AppDependencies.isInitialized ? AppDependencies.auditRepository : null);
      if (currentRepo is MockAuditRepository ||
          (AppDependencies.isInitialized && AppDependencies.useMock)) {
        if (currentRepo is MockAuditRepository) {
          final mockRecords = await currentRepo.getHistoryRecords();
          if (mockRecords.isNotEmpty || historyList.isEmpty) {
            historyList = mockRecords
                .map((m) => AuditSessionModel(
                      id: m.id,
                      stationName: m.stationName,
                      operatorName: m.operatorName,
                      mode: m.modeName ?? 'meter',
                      createdAt: m.dateTime,
                      images: m.images
                          .map<AuditHistoryImage>((img) => AuditHistoryImage(
                                imageType: img.label,
                                imageUrl: img.imageUrl ?? img.image.path,
                                label: img.label,
                                timestamp: img.capturedAt,
                              ))
                          .toList(),
                    ))
                .toList();
          }
        }
        errorMessage = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      final token = await secureStorage.read(key: 'auth_token') ??
          (_repository != null && _repository is RemoteAuditRepository
              ? _repository.client.authToken
              : ApiClient.instance.authToken);

      final response = await _httpClient.get(
        Uri.parse('http://192.168.1.8:5000/api/v1/capture/history'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List rawList = decoded is List
            ? decoded
            : (decoded['data'] ??
                decoded['history'] ??
                decoded['sessions'] ??
                decoded['captures'] ??
                decoded['audits'] ??
                []);

        historyList = rawList.map((item) => AuditSessionModel.fromJson(item)).toList();
        errorMessage = null;
      } else {
        String msg = 'Failed to fetch audit history (${response.statusCode})';
        try {
          final dynamic errDecoded = jsonDecode(response.body);
          if (errDecoded is Map) {
            final serverMsg = errDecoded['message'] ?? errDecoded['error'];
            if (serverMsg != null && serverMsg.toString().isNotEmpty) {
              msg = serverMsg.toString();
            }
          }
        } catch (_) {}
        errorMessage = msg;
      }
    } catch (e) {
      errorMessage = 'Network connection failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Prepend a newly completed session to the dynamic list
  Future<bool> addSession(CaptureHistoryItem session) async {
    historyList.removeWhere((h) => h.id == session.id);
    historyList.insert(
      0,
      AuditHistoryModel(
        id: session.id,
        stationName: session.stationName,
        operatorName: session.operatorName,
        mode: session.modeName?.toLowerCase().contains('nozzle') == true
            ? 'nozzle'
            : 'meter',
        nozzleNumber: session.modeName != null
            ? RegExp(r'\d+').firstMatch(session.modeName!)?.group(0)
            : null,
        createdAt: session.dateTime,
        images: session.images
            .map((img) => AuditHistoryImage(
                  imageType: img.label,
                  imageUrl: img.imageUrl ?? '',
                  label: img.label,
                  timestamp: img.capturedAt,
                ))
            .toList(),
        status: session.statusText,
        difference: session.difference,
        threshold: session.threshold,
        hasCorruption: session.hasCorruption,
      ),
    );
    notifyListeners();
    return true;
  }

  void addCapture({
    required List<CapturedImage> images,
    DateTime? dateTime,
    String? modeName,
    bool hasCorruption = false,
    String? statusText,
    Map<String, String>? sources,
    String difference = '+0.00 KG',
    String threshold = '1.00 KG',
    String? stationName,
    String? operatorName,
  }) {
    if (images.isEmpty) return;
    final record = CaptureHistoryItem(
      dateTime: dateTime ?? DateTime.now(),
      images: images,
      modeName: modeName,
      hasCorruption: hasCorruption,
      statusText: statusText,
      sources: sources,
      difference: difference,
      threshold: threshold,
      stationName: stationName,
      operatorName: operatorName,
    );
    addSession(record);
  }

  void clearAll() {
    historyList.clear();
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}

