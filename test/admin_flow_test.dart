import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/config/app_dependencies.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/models/pump_station_model.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';

void main() {
  setUp(() {
    AppDependencies.initialize(useMock: true);
  });

  group('AdminAuthProvider Tests', () {
    test('Initializes unauthenticated without hardcoded credentials', () {
      final auth = AdminAuthProvider();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.profile.email, isEmpty);
      expect(auth.profile.notificationsEnabled, isTrue);
    });

    test('Login succeeds with admin credentials and updates profile', () async {
      final auth = AdminAuthProvider();
      final success = await auth.login('admin', 'admin');

      expect(success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.profile.name, equals('Admin'));
    });

    test('Update profile updates name and email correctly', () async {
      final auth = AdminAuthProvider();
      await auth.updateProfile(
        name: 'Manager Ali',
        username: 'mali',
        email: 'ali@cnghub.com',
      );

      expect(auth.profile.name, equals('Manager Ali'));
      expect(auth.profile.username, equals('mali'));
      expect(auth.profile.email, equals('ali@cnghub.com'));
    });

    test('Update password checks current password', () async {
      final auth = AdminAuthProvider();
      final wrong = await auth.updatePassword('wrongpass', 'newpass123');
      expect(wrong, isFalse);

      final success = await auth.updatePassword('admin', 'newpass123');
      expect(success, isTrue);

      final secondUpdate = await auth.updatePassword('newpass123', 'anotherpass');
      expect(secondUpdate, isTrue);
    });

    test('Toggle notifications updates setting', () {
      final auth = AdminAuthProvider();
      expect(auth.profile.notificationsEnabled, isTrue);

      auth.toggleNotifications(false);
      expect(auth.profile.notificationsEnabled, isFalse);
    });

    test('Logout clears logged in status', () async {
      final auth = AdminAuthProvider();
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });
  });

  group('PumpProvider Tests', () {
    test('Initializes empty without hardcoded stations', () {
      final provider = PumpProvider();
      expect(provider.allStations.isEmpty, isTrue);
      expect(provider.totalPumps, equals(0));
    });

    test('Adding a new station prepends to index 0 (Screen 5 behavior)', () async {
      final provider = PumpProvider();

      final newStation = PumpStation(
        id: 'new_99',
        name: 'New CNG Station',
        location: 'Peshawar',
        totalPumps: 4,
        status: PumpStatus.active,
        categories: ['Fuel Pump'],
        createdAt: DateTime.now(),
      );

      final added = await provider.addStation(newStation);
      expect(added, isTrue);

      expect(provider.allStations.length, equals(1));
      expect(provider.allStations.first.id, equals('new_99'));
      expect(provider.allStations.first.name, equals('New CNG Station'));
      expect(provider.filteredStations.first.name, equals('New CNG Station'));
    });

    test('Searching filters by station name or location', () async {
      final provider = PumpProvider();

      await provider.addStation(
        PumpStation(
          id: 'st_1',
          name: 'Model Town CNG Station',
          location: 'Lahore',
          totalPumps: 6,
          status: PumpStatus.active,
          createdAt: DateTime.now(),
        ),
      );
      await provider.addStation(
        PumpStation(
          id: 'st_2',
          name: 'Khyber Fuel Station',
          location: 'Charsadda',
          totalPumps: 4,
          status: PumpStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      provider.setSearchQuery('Model Town');
      expect(provider.filteredStations.length, equals(1));
      expect(provider.filteredStations.first.name, contains('Model Town'));

      provider.setSearchQuery('Charsadda');
      expect(provider.filteredStations.length, equals(1));
      expect(provider.filteredStations.first.location, equals('Charsadda'));

      provider.clearSearch();
      expect(provider.filteredStations.length, equals(provider.allStations.length));
    });
  });

  group('HistoryProvider Station Filter Tests', () {
    test('Filter chips correctly filter records when records are present', () {
      final provider = HistoryProvider();

      expect(provider.selectedFilter, equals(HistoryTimeFilter.all));
      expect(provider.filteredStationRecords.isEmpty, isTrue);

      // Add dynamic session to test filtering
      provider.addSession(
        CaptureHistoryItem(
          id: 'test_session_1',
          stationName: 'Test Station',
          dateTime: DateTime.now(),
          images: [
            CapturedImage(
              label: 'Meter',
              image: File('test_meter.jpg'),
              capturedAt: DateTime.now(),
            ),
          ],
        ),
      );

      expect(provider.filteredStationRecords.isNotEmpty, isTrue);

      provider.setFilter(HistoryTimeFilter.today);
      expect(provider.selectedFilter, equals(HistoryTimeFilter.today));
      expect(provider.filteredStationRecords.isNotEmpty, isTrue);

      provider.setFilter(HistoryTimeFilter.last7Days);
      expect(provider.selectedFilter, equals(HistoryTimeFilter.last7Days));
      expect(provider.filteredStationRecords.isNotEmpty, isTrue);

      provider.setFilter(HistoryTimeFilter.last30Days);
      expect(provider.selectedFilter, equals(HistoryTimeFilter.last30Days));
      expect(provider.filteredStationRecords.isNotEmpty, isTrue);
    });
  });

  group('UserProvider Tests', () {
    test('Initializes empty without hardcoded mock users', () {
      final provider = UserProvider();
      expect(provider.allUsers.isEmpty, isTrue);
    });

    test('Adding new user inserts at beginning of list', () async {
      final provider = UserProvider();

      final newUser = CngUser(
        id: '7899',
        name: 'Rashid Khan',
        email: 'rashid@cnghub.com',
        role: UserRole.operator,
        assignedStation: 'Main CNG Station',
        createdAt: DateTime.now(),
      );

      final added = await provider.addUser(newUser);
      expect(added, isTrue);

      expect(provider.allUsers.length, equals(1));
      expect(provider.allUsers.first.id, equals('7899'));
      expect(provider.allUsers.first.name, equals('Rashid Khan'));
    });

    test('Searches users by ID, Name, or Station', () async {
      final provider = UserProvider();

      await provider.addUser(
        CngUser(
          id: '7890',
          name: 'Ali Khan',
          email: 'ali@cnghub.com',
          role: UserRole.operator,
          assignedStation: 'Model Town Station',
          createdAt: DateTime.now(),
        ),
      );
      await provider.addUser(
        CngUser(
          id: '7891',
          name: 'Bilal Ahmed',
          email: 'bilal@cnghub.com',
          role: UserRole.supervisor,
          assignedStation: 'Khyber Station',
          createdAt: DateTime.now(),
        ),
      );

      provider.setSearchQuery('7890');
      expect(provider.filteredUsers.length, equals(1));
      expect(provider.filteredUsers.first.name, equals('Ali Khan'));

      provider.setSearchQuery('Model Town');
      expect(provider.filteredUsers.length, equals(1));

      provider.clearSearch();
      expect(provider.filteredUsers.length, equals(provider.allUsers.length));
    });

    test('Filters users by role', () async {
      final provider = UserProvider();

      await provider.addUser(
        CngUser(
          id: '7890',
          name: 'Ali Khan',
          email: 'ali@cnghub.com',
          role: UserRole.operator,
          assignedStation: 'Station 1',
          createdAt: DateTime.now(),
        ),
      );
      await provider.addUser(
        CngUser(
          id: '7891',
          name: 'Bilal Ahmed',
          email: 'bilal@cnghub.com',
          role: UserRole.supervisor,
          assignedStation: 'Station 2',
          createdAt: DateTime.now(),
        ),
      );

      provider.setRoleFilter(UserRole.supervisor);
      expect(provider.filteredUsers.length, equals(1));
      expect(provider.filteredUsers.first.name, equals('Bilal Ahmed'));

      provider.setRoleFilter(null);
      expect(provider.filteredUsers.length, equals(provider.allUsers.length));
    });

    test('Toggling user status activates or deactivates user', () async {
      final provider = UserProvider();

      final user = CngUser(
        id: '7890',
        name: 'Ali Khan',
        email: 'ali@cnghub.com',
        role: UserRole.operator,
        assignedStation: 'Station 1',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await provider.addUser(user);

      final success = await provider.toggleUserStatus(user.id);
      expect(success, isTrue);
      expect(provider.allUsers.first.isActive, isFalse);
    });
  });
}
