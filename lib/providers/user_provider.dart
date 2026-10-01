import 'package:flutter/foundation.dart';
import '../config/app_dependencies.dart';
import '../models/cng_user_model.dart';
import '../repositories/user_repository.dart';
import '../widgets/shared_widgets/async_state_view.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  String _searchQuery = '';
  UserRole? _selectedRole;
  AsyncStatus _status = AsyncStatus.empty;
  String? _errorMessage;

  final List<CngUser> _users = [];

  UserProvider({UserRepository? repository})
      : _repository = repository ?? _resolveRepository() {
    _status = AsyncStatus.empty;
  }

  static UserRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.userRepository;
  }

  AsyncStatus get status => _status;
  bool get isLoading => _status == AsyncStatus.loading;
  bool get hasError => _status == AsyncStatus.error;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  UserRole? get selectedRole => _selectedRole;
  List<CngUser> get allUsers => List.unmodifiable(_users);

  List<CngUser> get filteredUsers {
    return _users.where((user) {
      final matchesQuery = _searchQuery.trim().isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
          user.id.contains(_searchQuery.trim()) ||
          user.assignedStation.toLowerCase().contains(_searchQuery.toLowerCase().trim());

      final matchesRole = _selectedRole == null || user.role == _selectedRole;

      return matchesQuery && matchesRole;
    }).toList();
  }

  /// Asynchronously fetch users from backend API
  Future<void> fetchUsers() async {
    _status = AsyncStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getUsers();
      _users.clear();
      _users.addAll(fetched);
      _status = _users.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
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

  void setRoleFilter(UserRole? role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> addUser(CngUser user) async {
    _status = AsyncStatus.loading;
    notifyListeners();

    try {
      final created = await _repository.addUser(user);
      _users.insert(0, created);
      _status = AsyncStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = _users.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(CngUser updatedUser) async {
    try {
      final updated = await _repository.updateUser(updatedUser);
      final index = _users.indexWhere((u) => u.id == updated.id);
      if (index != -1) {
        _users[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(String id) async {
    try {
      final updated = await _repository.toggleUserStatus(id);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repository.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      _status = _users.isEmpty ? AsyncStatus.empty : AsyncStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
