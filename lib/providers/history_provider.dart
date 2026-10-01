import 'package:flutter/material.dart';
import '../config/app_dependencies.dart';
import '../models/capture_history_item.dart';
import '../models/comparison_history_record.dart';
import '../models/station_history_item.dart';
import '../repositories/audit_repository.dart';
import '../services/api/api_exception.dart';
import '../widgets/shared_widgets/async_state_view.dart';

enum HistoryTimeFilter {
  all,
  today,
  last7Days,
  last30Days,
}

class HistoryProvider extends ChangeNotifier {
  final AuditRepository _repository;
  HistoryTimeFilter _selectedFilter = HistoryTimeFilter.all;
  AsyncStatus _status = AsyncStatus.empty;
  String? _errorMessage;

  final List<CaptureHistoryItem> _records = [];
  final List<StationHistoryItem> _stationRecords = [];
  final List<ComparisonHistoryRecord> _comparisonRecords = [];

  HistoryProvider({AuditRepository? repository})
      : _repository = repository ?? _resolveRepository() {
    _status = AsyncStatus.empty;
  }

  static AuditRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.auditRepository;
  }

  AsyncStatus get status => _status;
  bool get isLoading => _status == AsyncStatus.loading;
  bool get hasError => _status == AsyncStatus.error;
  String? get errorMessage => _errorMessage;

  HistoryTimeFilter get selectedFilter => _selectedFilter;
  List<CaptureHistoryItem> get records => List.unmodifiable(_records);
  List<StationHistoryItem> get stationRecords => List.unmodifiable(_stationRecords);
  List<ComparisonHistoryRecord> get comparisonRecords =>
      List.unmodifiable(_comparisonRecords);
  bool get isEmpty => _records.isEmpty && _stationRecords.isEmpty;
  bool get isStationRecordsEmpty => _stationRecords.isEmpty;

  List<StationHistoryItem> get filteredStationRecords {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case HistoryTimeFilter.today:
        return _stationRecords.where((item) {
          final diff = now.difference(item.timestamp);
          return diff.inDays == 0 && item.timestamp.day == now.day;
        }).toList();
      case HistoryTimeFilter.last7Days:
        return _stationRecords.where((item) {
          return now.difference(item.timestamp).inDays <= 7;
        }).toList();
      case HistoryTimeFilter.last30Days:
        return _stationRecords.where((item) {
          return now.difference(item.timestamp).inDays <= 30;
        }).toList();
      case HistoryTimeFilter.all:
        return List.unmodifiable(_stationRecords);
    }
  }

  /// All completed operator audit sessions (strictly real-time dynamic captures)
  List<CaptureHistoryItem> get auditSessions {
    if (_records.isNotEmpty) {
      return List.unmodifiable(_records);
    }
    if (_stationRecords.isNotEmpty) {
      final fromStations =
          filteredStationRecords.map((s) => s.toCaptureHistoryItem()).toList();
      return List.unmodifiable(fromStations);
    }
    return const [];
  }

  CaptureHistoryItem? findSessionById(String id) {
    try {
      return auditSessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Asynchronously fetch real-time submitted photos and session feeds from API
  Future<void> fetchHistory() async {
    _status = AsyncStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getHistoryRecords();
      _records.clear();
      _records.addAll(fetched);

      _stationRecords.clear();
      _stationRecords.addAll(
        fetched.map((h) => StationHistoryItem.fromCaptureHistoryItem(h)),
      );

      _status = _records.isEmpty && _stationRecords.isEmpty
          ? AsyncStatus.empty
          : AsyncStatus.loaded;
    } catch (e) {
      _status = AsyncStatus.error;
      final rawError = e is ApiException ? e.message : e.toString();
      _errorMessage = rawError.startsWith('Exception: ')
          ? rawError.substring(11)
          : rawError;
    }
    notifyListeners();
  }

  void setFilter(HistoryTimeFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Pushes a new dynamic session record immediately into memory and persists to API
  Future<bool> addSession(CaptureHistoryItem session) async {
    _records.removeWhere((r) => r.id == session.id);
    _records.insert(0, session);

    final stationItem = StationHistoryItem.fromCaptureHistoryItem(session);
    _stationRecords.removeWhere((s) => s.id == session.id);
    _stationRecords.insert(0, stationItem);

    _status = AsyncStatus.loaded;
    notifyListeners();

    try {
      await _repository.saveHistoryRecord(session);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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
    _records.clear();
    _stationRecords.clear();
    _comparisonRecords.clear();
    _status = AsyncStatus.empty;
    notifyListeners();
  }
}
