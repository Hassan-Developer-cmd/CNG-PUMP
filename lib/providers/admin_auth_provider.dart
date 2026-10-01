import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_dependencies.dart';
import '../constants/api_constants.dart';
import '../constants/api_endpoints.dart';
import '../models/admin_profile_model.dart';
import '../models/cng_user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/api/api_client.dart';
import '../services/api/api_exception.dart';
import '../services/api/auth_storage.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final ApiClient _client;
  final http.Client _httpClient;
  bool _isLoggedIn = false;
  AdminProfile? _profile;
  CngUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AdminAuthProvider({
    AuthRepository? repository,
    ApiClient? client,
    http.Client? httpClient,
  })  : _repository = repository ?? _resolveRepository(),
        _client = client ?? ApiClient.instance,
        _httpClient = httpClient ?? (client?.httpClient ?? ApiClient.instance.httpClient) {
    _restoreSavedSession();
  }

  static AuthRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.authRepository;
  }

  AuthStorage get secureStorage => AuthStorage.instance;

  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) => _isLoggedIn = value;

  bool get isLoading => _isLoading;
  set isLoading(bool value) => _isLoading = value;

  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) => _errorMessage = value;

  CngUser? get currentUser => _currentUser;
  set currentUser(dynamic value) {
    if (value is CngUser) {
      _currentUser = value;
      _profile = AdminProfile(
        name: value.name,
        username: value.email,
        email: value.email,
      );
    } else if (value is Map<String, dynamic> || value is Map) {
      final map = value is Map<String, dynamic>
          ? value
          : (value as Map).map((k, v) => MapEntry(k.toString(), v));

      final hasUserFields = map.containsKey('email') ||
          map.containsKey('name') ||
          map.containsKey('username') ||
          map.containsKey('role') ||
          map.containsKey('_id') ||
          map.containsKey('id');

      if (hasUserFields) {
        _currentUser = CngUser.fromJson(map);
        final emailVal = map['email']?.toString() ?? _currentUser?.email ?? '';
        final nameVal = map['name']?.toString() ?? map['username']?.toString() ?? _currentUser?.name ?? '';
        _profile = AdminProfile(
          name: nameVal.isNotEmpty ? nameVal : (emailVal.contains('@') ? emailVal.split('@').first : 'Admin'),
          username: emailVal,
          email: emailVal,
        );
      } else {
        _currentUser = null;
      }
    } else if (value == null) {
      _currentUser = null;
    }
  }

  AdminProfile get profile =>
      _profile ??
      AdminProfile(
        name: _currentUser?.name ?? '',
        username: _currentUser?.email ?? '',
        email: _currentUser?.email ?? '',
        notificationsEnabled: true,
      );

  /// Restores persisted JWT, profile, and user info from local storage
  Future<void> _restoreSavedSession() async {
    try {
      final token = await AuthStorage.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _client.setAuthToken(token);
        final savedProfile = await AuthStorage.instance.getAdminProfile();
        if (savedProfile != null) {
          _profile = savedProfile;
          _isLoggedIn = true;
        }
        final savedUser = await AuthStorage.instance.getUserInfo();
        if (savedUser != null) {
          _currentUser = CngUser.fromJson(savedUser);
          _isLoggedIn = true;
        }
        if (_isLoggedIn) {
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Dynamic Super Admin Login against API
  /// Sends { "email": email, "password": password } to http://192.168.1.8:5000/api/v1/auth/superadminlogin
  Future<bool> loginSuperAdmin({
    required String email,
    required String password,
    http.Client? client,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Fallback for mock test environment when explicitly configured
    if (AppDependencies.useMock && _repository is MockAuthRepository) {
      final result = await _repository.loginAdmin(email.trim(), password.trim());
      if (result != null) {
        _isLoggedIn = true;
        _profile = result;
        _currentUser = CngUser(
          id: result.username,
          name: result.name,
          email: result.email,
          role: UserRole.admin,
          assignedStation: 'Headquarters',
          createdAt: DateTime.now(),
        );
        isLoading = false;
        notifyListeners();
        return true;
      }
    }

    try {
      final clientToUse = client ?? _httpClient;
      final response = await clientToUse.post(
        Uri.parse('http://192.168.1.8:5000/api/v1/auth/superadminlogin'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          "email": email.trim(),
          "password": password.trim(),
        }),
      );

      dynamic data;
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body);
        }
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract dynamic token and user details
        final token = data is Map
            ? (data['token'] ?? data['accessToken'] ?? data['data']?['token'])
            : null;
        if (token != null) {
          final tokenStr = token.toString();
          await secureStorage.write(key: 'auth_token', value: tokenStr);
          _client.setAuthToken(tokenStr);
        }
        currentUser = data is Map ? (data['user'] ?? data['admin'] ?? data['data']) : null;
        if (_currentUser == null || _currentUser!.email.isEmpty) {
          final cleanEmail = email.trim();
          final namePart = cleanEmail.contains('@') ? cleanEmail.split('@').first : cleanEmail;
          _currentUser = CngUser(
            id: cleanEmail,
            name: namePart.isNotEmpty ? namePart : 'Super Admin',
            email: cleanEmail,
            role: UserRole.admin,
            assignedStation: 'Headquarters',
            createdAt: DateTime.now(),
          );
          _profile = AdminProfile(
            name: _currentUser!.name,
            username: cleanEmail,
            email: cleanEmail,
          );
        }
        if (_currentUser != null) {
          await AuthStorage.instance.saveUserInfo(_currentUser!.toJson());
        }
        if (_profile != null) {
          await AuthStorage.instance.saveAdminProfile(_profile!);
        }
        isLoggedIn = true;
        return true;
      } else {
        errorMessage = (data is Map ? (data['message'] ?? data['error']) : null) ??
            'Login failed (${response.statusCode})';
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Dynamic Admin Login delegating to [loginSuperAdmin]
  Future<bool> login(String email, String password) async {
    return loginSuperAdmin(email: email, password: password);
  }

  /// Dynamic Operator Login against API
  /// Sends { "email": email, "password": password } to /api/v1/auth/adminlogin
  Future<CngUser?> operatorLogin(String emailOrId, [String? password]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.loginOperator(emailOrId, password);
      _isLoading = false;
      if (result == null) {
        _errorMessage = 'Invalid credentials or server unreachable.';
        _isLoggedIn = false;
        _currentUser = null;
      } else {
        _isLoggedIn = true;
        _currentUser = result;
        _profile = AdminProfile(
          name: result.name,
          username: result.email,
          email: result.email,
        );
      }
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Logout, clear in-memory state, and remove saved JWT token
  Future<void> logout() async {
    _isLoggedIn = false;
    _profile = null;
    _currentUser = null;
    _errorMessage = null;
    _client.clearAuthToken();
    try {
      await AuthStorage.instance.clear();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    required String email,
  }) async {
    _profile = profile.copyWith(
      name: name,
      username: username,
      email: email,
    );
    notifyListeners();

    try {
      final updated = await _repository.updateProfile(_profile!);
      _profile = updated;
      await AuthStorage.instance.saveAdminProfile(updated);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      if (!success) {
        _errorMessage = 'Current password is incorrect';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void toggleNotifications(bool enabled) {
    _profile = profile.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }

  void setCurrentUser(CngUser? user) {
    _currentUser = user;
    if (user != null) {
      _isLoggedIn = true;
      _profile = AdminProfile(
        name: user.name,
        username: user.email,
        email: user.email,
      );
    }
    notifyListeners();
  }
}
