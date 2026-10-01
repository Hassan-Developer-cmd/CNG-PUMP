import '../constants/api_endpoints.dart';
import '../models/cng_user_model.dart';
import '../services/api/api_client.dart';

abstract class UserRepository {
  List<CngUser> get initialUsers;
  Future<List<CngUser>> getUsers();
  Future<CngUser> addUser(CngUser user);
  Future<CngUser> updateUser(CngUser user);
  Future<CngUser> toggleUserStatus(String id);
  Future<void> deleteUser(String id);
}

/// Production-ready Remote API User Repository
class RemoteUserRepository implements UserRepository {
  final ApiClient _client;

  RemoteUserRepository({ApiClient? client, String? baseUrl})
      : _client = client ?? ApiClient.instance;

  @override
  List<CngUser> get initialUsers => const [];

  @override
  Future<List<CngUser>> getUsers() async {
    final response = await _client.get(ApiEndpoints.users);

    final List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['data'] is List) {
      list = response['data'] as List;
    } else if (response is Map && response['users'] is List) {
      list = response['users'] as List;
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => CngUser.fromJson(json))
        .toList();
  }

  @override
  Future<CngUser> addUser(CngUser user) async {
    final response = await _client.post(
      ApiEndpoints.users,
      body: user.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final json = response['data'] is Map ? response['data'] : response;
      return CngUser.fromJson(json as Map<String, dynamic>);
    }
    return user;
  }

  @override
  Future<CngUser> updateUser(CngUser user) async {
    final response = await _client.put(
      ApiEndpoints.userDetail(user.id),
      body: user.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final json = response['data'] is Map ? response['data'] : response;
      return CngUser.fromJson(json as Map<String, dynamic>);
    }
    return user;
  }

  @override
  Future<CngUser> toggleUserStatus(String id) async {
    final response = await _client.patch(
      ApiEndpoints.userStatus(id),
    );

    if (response is Map<String, dynamic>) {
      final json = response['data'] is Map ? response['data'] : response;
      return CngUser.fromJson(json as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle user status');
  }

  @override
  Future<void> deleteUser(String id) async {
    await _client.delete(ApiEndpoints.userDetail(id));
  }
}

/// Fallback Mock User Repository without preset dummy users
class MockUserRepository implements UserRepository {
  final List<CngUser> _users = [];

  @override
  List<CngUser> get initialUsers => const [];

  @override
  Future<List<CngUser>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 20));
    return List.unmodifiable(_users);
  }

  @override
  Future<CngUser> addUser(CngUser user) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _users.insert(0, user);
    return user;
  }

  @override
  Future<CngUser> updateUser(CngUser user) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
    return user;
  }

  @override
  Future<CngUser> toggleUserStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      final updated = _users[index].copyWith(isActive: !_users[index].isActive);
      _users[index] = updated;
      return updated;
    }
    throw Exception('User not found');
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _users.removeWhere((u) => u.id == id);
  }
}
