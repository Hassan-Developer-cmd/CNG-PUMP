import '../constants/api_endpoints.dart';
import '../models/pump_station_model.dart';
import '../services/api/api_client.dart';

abstract class PumpRepository {
  List<PumpStation> get initialStations;
  Future<List<PumpStation>> getStations();
  Future<PumpStation> addStation(PumpStation station);
  Future<PumpStation> updateStation(PumpStation station);
  Future<void> deleteStation(String id);
}

/// Production-ready Remote API Pump Repository
class RemotePumpRepository implements PumpRepository {
  final ApiClient _client;

  RemotePumpRepository({ApiClient? client, String? baseUrl})
      : _client = client ?? ApiClient.instance;

  @override
  List<PumpStation> get initialStations => const [];

  @override
  Future<List<PumpStation>> getStations() async {
    final response = await _client.get(ApiEndpoints.pumps);

    final List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['data'] is List) {
      list = response['data'] as List;
    } else if (response is Map && response['pumps'] is List) {
      list = response['pumps'] as List;
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => PumpStation.fromJson(json))
        .toList();
  }

  @override
  Future<PumpStation> addStation(PumpStation station) async {
    final response = await _client.post(
      ApiEndpoints.pumps,
      body: station.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final json = response['data'] is Map ? response['data'] : response;
      return PumpStation.fromJson(json as Map<String, dynamic>);
    }
    return station;
  }

  @override
  Future<PumpStation> updateStation(PumpStation station) async {
    final response = await _client.put(
      ApiEndpoints.pumpDetail(station.id),
      body: station.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final json = response['data'] is Map ? response['data'] : response;
      return PumpStation.fromJson(json as Map<String, dynamic>);
    }
    return station;
  }

  @override
  Future<void> deleteStation(String id) async {
    await _client.delete(ApiEndpoints.pumpDetail(id));
  }
}

/// Fallback Mock Pump Repository without preset dummy stations
class MockPumpRepository implements PumpRepository {
  final List<PumpStation> _stations = [];

  @override
  List<PumpStation> get initialStations => const [];

  @override
  Future<List<PumpStation>> getStations() async {
    await Future.delayed(const Duration(milliseconds: 20));
    return List.unmodifiable(_stations);
  }

  @override
  Future<PumpStation> addStation(PumpStation station) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _stations.insert(0, station);
    return station;
  }

  @override
  Future<PumpStation> updateStation(PumpStation station) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _stations.indexWhere((s) => s.id == station.id);
    if (index != -1) {
      _stations[index] = station;
    }
    return station;
  }

  @override
  Future<void> deleteStation(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _stations.removeWhere((s) => s.id == id);
  }
}
