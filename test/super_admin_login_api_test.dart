import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:cng_pump/constants/api_constants.dart';
import 'package:cng_pump/constants/api_endpoints.dart';
import 'package:cng_pump/models/admin_profile_model.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/screens/auth/admin_login_screen.dart';
import 'package:cng_pump/screens/dashboard/admin_dashboard_screen.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/services/api/auth_storage.dart';

Widget _buildTestApp({
  required Widget home,
  required AdminAuthProvider adminAuthProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminAuthProvider>.value(value: adminAuthProvider),
      ChangeNotifierProvider(create: (_) => PumpProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => CaptureProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        home: home,
      ),
    ),
  );
}

void main() {
  setUp(() async {
    ApiConstants.setBaseUrl('http://192.168.1.8:5000');
    await AuthStorage.instance.clear();
  });

  group('Super Admin Login API Specification & Provider Tests', () {
    test('ApiEndpoints.superAdminLogin is configured to /api/v1/auth/superadminlogin', () {
      expect(ApiEndpoints.superAdminLogin, equals('/api/v1/auth/superadminlogin'));
    });

    test('loginSuperAdmin makes exact POST request to http://192.168.1.8:5000/api/v1/auth/superadminlogin with headers and body', () async {
      String? capturedUrl;
      String? capturedMethod;
      Map<String, String>? capturedHeaders;
      String? capturedBody;

      final mockHttp = MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedMethod = request.method;
        capturedHeaders = request.headers;
        capturedBody = request.body;

        return http.Response(
          jsonEncode({
            "token": "super_secret_jwt_token_12345",
            "user": {
              "_id": "sa_001",
              "name": "Chief Super Admin",
              "email": "superadmin@cnghub.com",
              "role": "admin",
              "assignedStation": "HQ Central",
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final provider = AdminAuthProvider(client: apiClient, httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: '  superadmin@cnghub.com  ',
        password: '  SecretPass123!  ',
      );

      // Verify URL
      expect(capturedUrl, equals('http://192.168.1.8:5000/api/v1/auth/superadminlogin'));

      // Verify Method
      expect(capturedMethod, equals('POST'));

      // Verify Headers
      expect(capturedHeaders?['Content-Type'], equals('application/json'));
      expect(capturedHeaders?['Accept'], equals('application/json'));

      // Verify Body (trimmed)
      final bodyMap = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(bodyMap['email'], equals('superadmin@cnghub.com'));
      expect(bodyMap['password'], equals('SecretPass123!'));

      // Verify Return and State
      expect(success, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.currentUser?.name, equals('Chief Super Admin'));

      // Verify Token Saved to SecureStorage & ApiClient
      final savedToken = await provider.secureStorage.read(key: 'auth_token');
      expect(savedToken, equals('super_secret_jwt_token_12345'));
      expect(apiClient.authToken, equals('super_secret_jwt_token_12345'));
    });

    test('loginSuperAdmin handles 201 Created and extracts accessToken or nested data.token', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "accessToken": "bearer_access_token_999",
            "admin": {
              "name": "Regional Admin",
              "email": "regional@cnghub.com",
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'regional@cnghub.com',
        password: 'pass',
      );

      expect(success, isTrue);
      expect(provider.isLoggedIn, isTrue);
      final savedToken = await provider.secureStorage.read(key: 'auth_token');
      expect(savedToken, equals('bearer_access_token_999'));
    });

    test('loginSuperAdmin extracts nested data.token and fallback user info', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "data": {
              "token": "nested_token_888",
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'solo@cnghub.com',
        password: 'pass',
      );

      expect(success, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.currentUser?.email, equals('solo@cnghub.com'));
      final savedToken = await provider.secureStorage.read(key: 'auth_token');
      expect(savedToken, equals('nested_token_888'));
    });

    test('loginSuperAdmin handles 401 Unauthorized with custom error message', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({"message": "Invalid Super Admin credentials"}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'wrong@cnghub.com',
        password: 'wrongpassword',
      );

      expect(success, isFalse);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.errorMessage, equals('Invalid Super Admin credentials'));
      expect(provider.isLoading, isFalse);
    });

    test('loginSuperAdmin handles 400 Bad Request with error field', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({"error": "Email and password required"}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'bad@cnghub.com',
        password: '',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, equals('Email and password required'));
    });

    test('loginSuperAdmin handles 500 Internal Server Error with fallback code', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          'Server Error Occurred',
          500,
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'admin@cnghub.com',
        password: 'pass',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('500'));
    });

    test('loginSuperAdmin handles network exception with Network error prefix', () async {
      final mockHttp = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      final success = await provider.loginSuperAdmin(
        email: 'admin@cnghub.com',
        password: 'pass',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('Network error:'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AdminLoginScreen UI & Form Wiring Tests', () {
    testWidgets('Empty fields show form validation error and do not call API', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool apiCalled = false;
      final mockHttp = MockClient((request) async {
        apiCalled = true;
        return http.Response('{}', 200);
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const AdminLoginScreen(),
        adminAuthProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap Enter Admin Dashboard without filling inputs
      await tester.tap(find.text('Enter Admin Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter administrator email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(apiCalled, isFalse);
    });

    testWidgets('Valid credentials call loginSuperAdmin, show spinner and navigate to AdminDashboardScreen on success', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response(
          jsonEncode({
            "token": "valid_token_xyz",
            "user": {
              "name": "Super Admin User",
              "email": "superadmin@cnghub.com",
              "role": "admin",
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const AdminLoginScreen(),
        adminAuthProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'superadmin@cnghub.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Secret1234');
      await tester.pump();

      // Tap Submit Button
      await tester.tap(find.text('Enter Admin Dashboard'));
      await tester.pump(); // Start execution

      // While executing, CircularProgressIndicator is shown on button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish async call
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Navigated to Admin Dashboard
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
    });

    testWidgets('Failed loginSuperAdmin shows backend error message in SnackBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({"message": "Invalid Super Admin credentials. Access denied."}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = AdminAuthProvider(httpClient: mockHttp);

      await tester.pumpWidget(_buildTestApp(
        home: const AdminLoginScreen(),
        adminAuthProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'badadmin@cnghub.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.pump();

      // Tap Submit Button
      await tester.tap(find.text('Enter Admin Dashboard'));
      await tester.pumpAndSettle();

      // Still on AdminLoginScreen (did not navigate)
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);

      // SnackBar with backend message is displayed
      expect(find.text('Invalid Super Admin credentials. Access denied.'), findsOneWidget);
    });
  });
}
