import 'package:flutter/foundation.dart';
import '../config/app_dependencies.dart';
import '../models/admin_profile_model.dart';
import '../models/cng_user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/api/api_client.dart';
import '../services/api/api_exception.dart';
import '../services/api/auth_storage.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final ApiClient _client;
  bool _isLoggedIn = false;
  AdminProfile? _profile;
  CngUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AdminAuthProvider({AuthRepository? repository, ApiClient? client})
      : _repository = repository ?? _resolveRepository(),
        _client = client ?? ApiClient.instance {
    _restoreSavedSession();
  }

  static AuthRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.authRepository;
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CngUser? get currentUser => _currentUser;
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

  /// Dynamic Admin Login against API
  /// Sends { "email": email, "password": password } to /api/v1/auth/adminlogin
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.loginAdmin(email.trim(), password);
      if (result != null) {
        _isLoggedIn = true;
        _profile = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        _errorMessage = 'Invalid credentials or server unreachable';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _isLoggedIn = false;
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoggedIn = false;
      _errorMessage = 'Invalid credentials or server unreachable: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
}
