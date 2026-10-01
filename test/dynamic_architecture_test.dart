import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cng_pump/config/app_dependencies.dart';
import 'package:cng_pump/models/admin_profile_model.dart';
import 'package:cng_pump/models/audit_config_model.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/models/comparison_history_record.dart';
import 'package:cng_pump/models/pump_station_model.dart';
import 'package:cng_pump/models/station_history_item.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/repositories/repositories.dart';
import 'package:cng_pump/widgets/shared_widgets/async_state_view.dart';

void main() {
  setUp(() {
    AppDependencies.initialize(useMock: true);
  });

  group('Model Serialization Tests (fromJson / toJson)', () {
    test('AdminProfile serialization roundtrip', () {
      const profile = AdminProfile(
        name: 'Super Admin',
        username: 'sadmin',
        email: 'sadmin@cnghub.com',
        avatarUrl: 'https://cnghub.com/avatar.png',
        notificationsEnabled: false,
      );

      final json = profile.toJson();
      final fromJson = AdminProfile.fromJson(json);

      expect(fromJson.name, equals(profile.name));
      expect(fromJson.username, equals(profile.username));
      expect(fromJson.email, equals(profile.email));
      expect(fromJson.avatarUrl, equals(profile.avatarUrl));
      expect(fromJson.notificationsEnabled, equals(profile.notificationsEnabled));
    });

    test('CngUser serialization roundtrip with UserRole', () {
      final user = CngUser(
        id: '9901',
        name: 'Zahid Khan',
        email: 'zahid@cnghub.com',
        phone: '+92 333 1112233',
        role: UserRole.supervisor,
        assignedStation: 'Ring Road CNG',
        isActive: true,
        createdAt: DateTime(2026, 9, 1, 10, 0),
      );

      final json = user.toJson();
      final fromJson = CngUser.fromJson(json);

      expect(fromJson.id, equals(user.id));
      expect(fromJson.name, equals(user.name));
      expect(fromJson.role, equals(UserRole.supervisor));
      expect(fromJson.assignedStation, equals(user.assignedStation));
      expect(fromJson.isActive, equals(user.isActive));
    });

    test('PumpStation serialization roundtrip with PumpStatus', () {
      final station = PumpStation(
        id: 'st_88',
        name: 'Kohat Road CNG',
        location: 'Kohat',
        totalPumps: 8,
        status: PumpStatus.active,
        assignedUserIds: const ['7890', '7891'],
        categories: const ['Fuel Pump', 'Meter'],
        notes: 'Highway hub',
        createdAt: DateTime(2026, 8, 15, 12, 0),
      );

      final json = station.toJson();
      final fromJson = PumpStation.fromJson(json);

      expect(fromJson.id, equals(station.id));
      expect(fromJson.name, equals(station.name));
      expect(fromJson.totalPumps, equals(station.totalPumps));
      expect(fromJson.status, equals(PumpStatus.active));
      expect(fromJson.assignedUserIds, equals(station.assignedUserIds));
      expect(fromJson.categories, equals(station.categories));
    });

    test('StationHistoryItem serialization roundtrip', () {
      final item = StationHistoryItem(
        id: 'h_100',
        stationName: 'Test Station',
        location: 'Islamabad',
        timestamp: DateTime(2026, 9, 20, 8, 30),
        timeDisplay: '08:30 AM',
        isChecked: true,
      );

      final json = item.toJson();
      final fromJson = StationHistoryItem.fromJson(json);

      expect(fromJson.id, equals(item.id));
      expect(fromJson.stationName, equals(item.stationName));
      expect(fromJson.location, equals(item.location));
      expect(fromJson.timeDisplay, equals(item.timeDisplay));
    });

    test('ComparisonHistoryRecord serialization roundtrip', () {
      const record = ComparisonHistoryRecord(
        dateTitle: '20/09/2026 - 15:00',
        hasCorruption: false,
        statusText: 'IN-SYNC (0.00 KG)',
        sources: {
          'Digital Machine': '1,200.00 KG',
          'Sui Gas': '1,200.00 KG',
        },
        difference: '+0.00 KG',
      );

      final json = record.toJson();
      final fromJson = ComparisonHistoryRecord.fromJson(json);

      expect(fromJson.dateTitle, equals(record.dateTitle));
      expect(fromJson.hasCorruption, isFalse);
      expect(fromJson.sources['Digital Machine'], equals('1,200.00 KG'));
    });

    test('AuditConfigModel serialization roundtrip', () {
      const config = AuditConfigModel(
        operatorName: 'Ali',
        operatorId: '7890',
        stationName: 'Custom CNG',
        countdownDurationSeconds: 120,
        availableNozzles: ['Nozzle 1', 'Nozzle 2'],
      );

      final json = config.toJson();
      final fromJson = AuditConfigModel.fromJson(json);

      expect(fromJson.operatorName, equals('Ali'));
      expect(fromJson.operatorId, equals('7890'));
      expect(fromJson.stationName, equals('Custom CNG'));
      expect(fromJson.formatPrompt('Nozzle 1'), contains('Nozzle 1'));
    });

    test('CaptureHistoryItem serialization roundtrip', () {
      final history = CaptureHistoryItem(
        dateTime: DateTime(2026, 9, 20, 14, 0),
        images: [],
        modeName: 'Nozzle 1',
      );

      final json = history.toJson();
      final fromJson = CaptureHistoryItem.fromJson(json);

      expect(fromJson.modeName, equals('Nozzle 1'));
      expect(fromJson.images, isEmpty);
    });

    test('CngReadingItem serialization roundtrip', () {
      final item = CngReadingItem(
        type: CngReadingType.meter,
        title: 'Meter',
        isRequired: true,
        icon: Icons.speed_outlined,
      );

      final json = item.toJson();
      final fromJson = CngReadingItem.fromJson(json);

      expect(fromJson.title, equals('Meter'));
      expect(fromJson.isRequired, isTrue);
    });
  });

  group('Repository Layer Asynchronous Network Simulation Tests', () {
    test('MockPumpRepository CRUD operations', () async {
      final repo = MockPumpRepository();
      final initial = repo.initialStations;
      expect(initial.isEmpty, isTrue);

      final fetched = await repo.getStations();
      expect(fetched.isEmpty, isTrue);

      final created = await repo.addStation(
        PumpStation(
          id: 'temp_1',
          name: 'Dynamic Station',
          location: 'Peshawar',
          totalPumps: 2,
          createdAt: DateTime.now(),
        ),
      );
      expect(created.id, equals('temp_1'));

      final listAfterAdd = await repo.getStations();
      expect(listAfterAdd.length, equals(1));

      await repo.deleteStation('temp_1');
      final listAfterDelete = await repo.getStations();
      expect(listAfterDelete.isEmpty, isTrue);
    });

    test('MockUserRepository CRUD operations', () async {
      final repo = MockUserRepository();
      final initial = repo.initialUsers;
      expect(initial.isEmpty, isTrue);

      final fetched = await repo.getUsers();
      expect(fetched.isEmpty, isTrue);

      final newUser = await repo.addUser(
        CngUser(
          id: 'test_user',
          name: 'Test Operator',
          email: 'test@cnghub.com',
          assignedStation: 'Main Station',
          createdAt: DateTime.now(),
        ),
      );
      expect(newUser.id, equals('test_user'));

      final toggled = await repo.toggleUserStatus('test_user');
      expect(toggled.isActive, isFalse);

      await repo.deleteUser('test_user');
      final listAfterDelete = await repo.getUsers();
      expect(listAfterDelete.any((u) => u.id == 'test_user'), isFalse);
    });

    test('MockAuthRepository login & profile update', () async {
      final repo = MockAuthRepository();

      final admin = await repo.loginAdmin('admin', 'admin');
      expect(admin, isNotNull);
      expect(admin!.username, equals('admin'));

      final operator = await repo.loginOperator('7890');
      expect(operator, isNotNull);
      expect(operator!.name, equals('Ali Khan'));

      final updatedProfile = await repo.updateProfile(
        admin.copyWith(name: 'Updated Name'),
      );
      expect(updatedProfile.name, equals('Updated Name'));
    });
  });

  group('Provider Dynamic State & Repository Connection Tests', () {
    test('PumpProvider handles async fetchStations with AsyncStatus transitions', () async {
      final repo = MockPumpRepository();
      await repo.addStation(
        PumpStation(
          id: 'st_1',
          name: 'Main CNG',
          location: 'Islamabad',
          totalPumps: 4,
          createdAt: DateTime.now(),
        ),
      );
      final provider = PumpProvider(repository: repo);

      expect(provider.status, equals(AsyncStatus.empty));
      expect(provider.isLoading, isFalse);

      final fetchFuture = provider.fetchStations();
      expect(provider.isLoading, isTrue);

      await fetchFuture;
      expect(provider.isLoading, isFalse);
      expect(provider.status, equals(AsyncStatus.loaded));
      expect(provider.allStations.isNotEmpty, isTrue);
    });

    test('UserProvider handles async fetchUsers with AsyncStatus transitions', () async {
      final repo = MockUserRepository();
      await repo.addUser(
        CngUser(
          id: 'u_1',
          name: 'Ali Khan',
          email: 'ali@cnghub.com',
          assignedStation: 'Main CNG',
          createdAt: DateTime.now(),
        ),
      );
      final provider = UserProvider(repository: repo);

      expect(provider.status, equals(AsyncStatus.empty));

      final fetchFuture = provider.fetchUsers();
      expect(provider.isLoading, isTrue);

      await fetchFuture;
      expect(provider.isLoading, isFalse);
      expect(provider.status, equals(AsyncStatus.loaded));
      expect(provider.allUsers.isNotEmpty, isTrue);
    });

    test('HistoryProvider handles clean initial state and async fetchHistory', () async {
      final repo = MockAuditRepository();
      final provider = HistoryProvider(repository: repo);

      // Initially starts empty per requirement
      expect(provider.auditSessions.isEmpty, isTrue);
      expect(provider.status, equals(AsyncStatus.empty));

      // Add dynamic real-time session
      final now = DateTime.now();
      provider.addSession(
        CaptureHistoryItem(
          dateTime: now,
          images: [
            CapturedImage(label: 'Meter', image: File(''), capturedAt: now),
          ],
        ),
      );

      expect(provider.auditSessions.length, equals(1));
      expect(provider.status, equals(AsyncStatus.loaded));

      await provider.fetchHistory();
      expect(provider.status, equals(AsyncStatus.loaded));
      expect(provider.auditSessions.length, equals(1));
    });
  });

  group('AsyncStateView UI Dynamic States Tests', () {
    testWidgets('Renders loading indicator when status is loading', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: AsyncStateView(
                status: AsyncStatus.loading,
                child: Text('Loaded Data'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.text('Loaded Data'), findsNothing);
    });

    testWidgets('Renders empty state with title and refresh button', (tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: AsyncStateView(
                status: AsyncStatus.empty,
                emptyTitle: 'No Pumps Found',
                emptySubtitle: 'Add your first pump to get started',
                onRetry: () => refreshed = true,
                child: const Text('Loaded Data'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Pumps Found'), findsOneWidget);
      expect(find.text('Add your first pump to get started'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(refreshed, isTrue);
    });

    testWidgets('Renders error state with retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: AsyncStateView(
                status: AsyncStatus.error,
                errorMessage: 'Connection timed out. Check your network.',
                onRetry: () => retried = true,
                child: const Text('Loaded Data'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to Load Data'), findsOneWidget);
      expect(find.text('Connection timed out. Check your network.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('Renders child data when status is loaded', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: AsyncStateView(
                status: AsyncStatus.loaded,
                child: Text('Dynamic Server Stations Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dynamic Server Stations Content'), findsOneWidget);
    });
  });
}
