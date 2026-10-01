import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/admin_profile_model.dart';

/// Persistent storage for JWT authentication tokens, session info, and credentials.
/// Includes in-memory fallback to ensure ultra-fast execution and complete resiliency.
class AuthStorage {
  static const String _keyToken = 'cng_auth_token';
  static const String _keyAdminProfile = 'cng_admin_profile';
  static const String _keyUserInfo = 'cng_user_info';
  static const String _keyRememberMe = 'cng_remember_me';
  static const String _keySavedEmail = 'cng_saved_email';

  static AuthStorage? _instance;
  static AuthStorage get instance => _instance ??= AuthStorage._();

  AuthStorage._();

  static SharedPreferences? _prefs;
  final Map<String, dynamic> _inMemoryFallback = {};

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 150));
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  /// Save JWT authentication token
  Future<void> saveToken(String token) async {
    _inMemoryFallback[_keyToken] = token;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyToken, token);
    } catch (_) {}
  }

  /// Retrieve saved JWT token
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final val = prefs.getString(_keyToken);
        if (val != null) return val;
      }
    } catch (_) {}
    return _inMemoryFallback[_keyToken] as String?;
  }

  /// Save Admin Profile
  Future<void> saveAdminProfile(AdminProfile profile) async {
    _inMemoryFallback[_keyAdminProfile] = profile;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyAdminProfile, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  /// Retrieve saved Admin Profile
  Future<AdminProfile?> getAdminProfile() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs?.getString(_keyAdminProfile);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return AdminProfile.fromJson(decoded);
        }
      }
    } catch (_) {}
    final fallback = _inMemoryFallback[_keyAdminProfile];
    if (fallback is AdminProfile) return fallback;
    return null;
  }

  /// Save User / Operator Info
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    _inMemoryFallback[_keyUserInfo] = userInfo;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyUserInfo, jsonEncode(userInfo));
    } catch (_) {}
  }

  /// Retrieve saved User / Operator Info
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs?.getString(_keyUserInfo);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    final fallback = _inMemoryFallback[_keyUserInfo];
    if (fallback is Map<String, dynamic>) return fallback;
    return null;
  }

  /// Save Remember Me preference and remembered email
  Future<void> saveRememberMe({required bool enabled, String? email}) async {
    _inMemoryFallback[_keyRememberMe] = enabled;
    if (enabled && email != null && email.trim().isNotEmpty) {
      _inMemoryFallback[_keySavedEmail] = email.trim();
    } else {
      _inMemoryFallback.remove(_keySavedEmail);
    }
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.setBool(_keyRememberMe, enabled);
        if (enabled && email != null && email.trim().isNotEmpty) {
          await prefs.setString(_keySavedEmail, email.trim());
        } else {
          await prefs.remove(_keySavedEmail);
        }
      }
    } catch (_) {}
  }

  /// Retrieve Remember Me flag
  Future<bool> getRememberMe() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        return prefs.getBool(_keyRememberMe) ??
            (_inMemoryFallback[_keyRememberMe] as bool? ?? false);
      }
    } catch (_) {}
    return _inMemoryFallback[_keyRememberMe] as bool? ?? false;
  }

  /// Retrieve saved email if Remember Me was enabled
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final remember = prefs.getBool(_keyRememberMe) ?? false;
        if (remember) {
          final val = prefs.getString(_keySavedEmail);
          if (val != null) return val;
        }
      }
    } catch (_) {}
    final remember = _inMemoryFallback[_keyRememberMe] as bool? ?? false;
    if (remember) {
      return _inMemoryFallback[_keySavedEmail] as String?;
    }
    return null;
  }

  /// Clear token, profile, and user info on logout (preserves remember me preference if set)
  Future<void> clear({bool clearRememberMe = false}) async {
    _inMemoryFallback.remove(_keyToken);
    _inMemoryFallback.remove(_keyAdminProfile);
    _inMemoryFallback.remove(_keyUserInfo);
    if (clearRememberMe) {
      _inMemoryFallback.remove(_keyRememberMe);
      _inMemoryFallback.remove(_keySavedEmail);
    }
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.remove(_keyToken);
        await prefs.remove(_keyAdminProfile);
        await prefs.remove(_keyUserInfo);
        if (clearRememberMe) {
          await prefs.remove(_keyRememberMe);
          await prefs.remove(_keySavedEmail);
        }
      }
    } catch (_) {}
  }
}
