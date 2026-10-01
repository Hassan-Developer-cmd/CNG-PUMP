import '../constants/api_endpoints.dart';
import '../models/admin_profile_model.dart';
import '../models/cng_user_model.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_storage.dart';

abstract class AuthRepository {
  Future<AdminProfile?> loginAdmin(String email, String password);
  Future<CngUser?> loginOperator(String operatorId, [String? password]);
  Future<AdminProfile> updateProfile(AdminProfile profile);
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Production-ready Remote API Authentication Repository
class RemoteAuthRepository implements AuthRepository {
  final ApiClient _client;

  RemoteAuthRepository({ApiClient? client, String? baseUrl})
      : _client = client ?? ApiClient.instance;

  @override
  Future<AdminProfile?> loginAdmin(String email, String password) async {
    final response = await _client.post(
      ApiEndpoints.adminLogin,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      // 1. Extract Token / JWT
      final token = response['token'] ??
          response['accessToken'] ??
          response['jwt'] ??
          (response['data'] is Map
              ? (response['data']['token'] ??
                  response['data']['accessToken'] ??
                  response['data']['jwt'])
              : null);

      if (token != null) {
        final tokenStr = token.toString();
        _client.setAuthToken(tokenStr);
        await AuthStorage.instance.saveToken(tokenStr);
      }

      // 2. Extract Admin User Profile
      final profileJson = response['user'] ??
          response['admin'] ??
          (response['data'] is Map
              ? (response['data']['user'] ??
                  response['data']['admin'] ??
                  response['data'])
              : null) ??
          response;

      AdminProfile profile;
      if (profileJson is Map<String, dynamic> &&
          (profileJson.containsKey('email') ||
              profileJson.containsKey('username') ||
              profileJson.containsKey('name'))) {
        profile = AdminProfile.fromJson(profileJson);
      } else {
        final cleanEmail = email.trim();
        final namePart = cleanEmail.contains('@')
            ? cleanEmail.split('@').first
            : cleanEmail;
        profile = AdminProfile(
          email: cleanEmail,
          username: cleanEmail,
          name: namePart.isNotEmpty ? namePart : 'Admin',
        );
      }

      await AuthStorage.instance.saveAdminProfile(profile);
      return profile;
    }
    return null;
  }

  @override
  Future<CngUser?> loginOperator(String operatorId, [String? password]) async {
    final response = await _client.post(
      ApiEndpoints.adminLogin,
      body: {
        'email': operatorId.trim(),
        'password': password ?? '',
      },
    );

    if (response is Map<String, dynamic>) {
      // 1. Extract Token / JWT / Bearer Token
      final token = response['token'] ??
          response['accessToken'] ??
          response['access_token'] ??
          response['jwt'] ??
          response['authToken'] ??
          (response['data'] is Map
              ? (response['data']['token'] ??
                  response['data']['accessToken'] ??
                  response['data']['access_token'] ??
                  response['data']['jwt'] ??
                  response['data']['authToken'])
              : null);

      if (token != null) {
        final tokenStr = token.toString();
        _client.setAuthToken(tokenStr);
        await AuthStorage.instance.saveToken(tokenStr);
      }

      // 2. Extract User Info
      final userJson = response['user'] ??
          response['operator'] ??
          response['admin'] ??
          (response['data'] is Map
              ? (response['data']['user'] ??
                  response['data']['operator'] ??
                  response['data']['admin'] ??
                  response['data'])
              : null) ??
          response;

      if (userJson is Map<String, dynamic>) {
        await AuthStorage.instance.saveUserInfo(userJson);

        final cleanEmail = operatorId.trim();
        final dynamicId = userJson['_id']?.toString() ??
            userJson['id']?.toString() ??
            cleanEmail;
        final dynamicName = userJson['name']?.toString() ??
            userJson['username']?.toString() ??
            (cleanEmail.contains('@') ? cleanEmail.split('@').first : cleanEmail);
        final dynamicEmail = userJson['email']?.toString() ?? cleanEmail;
        final dynamicRole = UserRoleExtension.fromString(userJson['role']?.toString());
        final assignedStation = userJson['assignedStation']?.toString() ??
            userJson['station']?.toString() ??
            userJson['stationName']?.toString() ??
            '';

        final user = CngUser(
          id: dynamicId.isNotEmpty ? dynamicId : cleanEmail,
          name: dynamicName.isNotEmpty ? dynamicName : cleanEmail,
          email: dynamicEmail,
          role: dynamicRole,
          assignedStation: assignedStation,
          phone: userJson['phone']?.toString() ?? '',
          isActive: userJson['isActive'] as bool? ?? true,
          createdAt: userJson['createdAt'] != null
              ? DateTime.tryParse(userJson['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );

        final profile = AdminProfile(
          email: dynamicEmail,
          username: dynamicEmail,
          name: dynamicName,
        );
        await AuthStorage.instance.saveAdminProfile(profile);

        return user;
      }
    }
    return null;
  }

  @override
  Future<AdminProfile> updateProfile(AdminProfile profile) async {
    final response = await _client.put(
      ApiEndpoints.profile,
      body: profile.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final userJson = response['user'] ?? response['data'] ?? response;
      if (userJson is Map<String, dynamic>) {
        return AdminProfile.fromJson(userJson);
      }
    }
    return profile;
  }

  @override
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      ApiEndpoints.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response != null;
  }
}

/// Fallback Mock Authentication Repository without hardcoded credentials
class MockAuthRepository implements AuthRepository {
  AdminProfile? _adminProfile;
  final List<CngUser> _mockOperators = [];

  @override
  Future<AdminProfile?> loginAdmin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final cleanEmail = email.trim();
    if (cleanEmail.isNotEmpty && password.trim().isNotEmpty) {
      final namePart = cleanEmail.contains('@') ? cleanEmail.split('@').first : cleanEmail;
      _adminProfile = AdminProfile(
        username: cleanEmail,
        email: cleanEmail.contains('@') ? cleanEmail : '$cleanEmail@cnghub.com',
        name: cleanEmail.toLowerCase() == 'admin' ? 'Admin' : (namePart.isNotEmpty ? namePart : 'Admin'),
      );
      return _adminProfile;
    }
    return null;
  }

  @override
  Future<CngUser?> loginOperator(String operatorId, [String? password]) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final cleanId = operatorId.trim();
    if (cleanId.isEmpty) return null;

    final existing = _mockOperators.where((u) => u.id == cleanId || u.email == cleanId);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final user = CngUser(
      id: cleanId,
      name: cleanId == '7890'
          ? 'Ali Khan'
          : (cleanId.contains('@') ? cleanId.split('@').first : 'Operator ($cleanId)'),
      email: cleanId.contains('@') ? cleanId : '$cleanId@cnghub.com',
      role: UserRole.operator,
      assignedStation: cleanId == '7890' ? 'Main CNG Station #01' : '',
      createdAt: DateTime.now(),
    );
    _mockOperators.add(user);
    return user;
  }

  @override
  Future<AdminProfile> updateProfile(AdminProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 20));
    _adminProfile = profile;
    return profile;
  }

  @override
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 20));
    if (currentPassword == 'wrongpass') {
      return false;
    }
    return newPassword.isNotEmpty;
  }
}
