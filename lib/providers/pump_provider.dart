import 'package:flutter/foundation.dart';
import '../config/app_dependencies.dart';
import '../models/pump_station_model.dart';
import '../repositories/pump_repository.dart';
import '../widgets/shared_widgets/async_state_view.dart';

class PumpProvider extends ChangeNotifier {
  final PumpRepository _repository;
  String _searchQuery = '';
  AsyncStatus _status = AsyncStatus.empty;
  String? _errorMessage;

  final List<PumpStation> _stations = [];

  PumpProvider({PumpRepository? repository})
      : _repository = repository ?? _resolveRepository() {
    _status = AsyncStatus.empty;
  }

  static PumpRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.pumpRepository;
  }

  AsyncStatus get status => _status;
  bool get isLoading => _status == AsyncStatus.loading;
  bool get hasError => _status == AsyncStatus.error;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  List<PumpStation> get allStations => List.unmodifiable(_stations);

  int get totalPumps => _stations.fold<int>(0, (sum, s) => sum + s.totalPumps);

  List<PumpStation> get filteredStations {
    if (_searchQuery.trim().isEmpty) {
      return _stations;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _stations.where((station) {
      return station.name.toLowerCase().contains(query) ||
          station.location.toLowerCase().contains(query);
    }).toList();
  }

  /// Asynchronously fetch stations from backend API
  Future<void> fetchStations() async {
    _status = AsyncStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getStations();
      _stations.clear();
      _stations.addAll(fetched);
      _status = _stations.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
    } catch (e) {
      _status = AsyncStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> addStation(PumpStation station) async {
    _status = AsyncStatus.loading;
    notifyListeners();

    try {
      final created = await _repository.addStation(station);
      _stations.insert(0, created);
      _status = AsyncStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = _stations.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStation(PumpStation updatedStation) async {
    try {
      final updated = await _repository.updateStation(updatedStation);
      final index = _stations.indexWhere((s) => s.id == updated.id);
      if (index != -1) {
        _stations[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStation(String id) async {
    try {
      await _repository.deleteStation(id);
      _stations.removeWhere((s) => s.id == id);
      _status = _stations.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
