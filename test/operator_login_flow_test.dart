import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cng_pump/constants/api_constants.dart';
import 'package:cng_pump/constants/api_endpoints.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/repositories/auth_repository.dart';
import 'package:cng_pump/screens/auth/login_screen.dart';
import 'package:cng_pump/screens/users/operator_user_screen.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/services/api/api_exception.dart';
import 'package:cng_pump/services/api/auth_storage.dart';

Widget _buildTestApp({
  required Widget home,
  AdminAuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminAuthProvider>(
        create: (_) => authProvider ?? AdminAuthProvider(),
      ),
      ChangeNotifierProvider(create: (_) => PumpProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => CaptureProvider()),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          home: home,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Operator Login & MongoDB Integration Tests', () {
    test('1. Base URL and Timeout configuration verification', () {
      expect(ApiConstants.defaultBaseUrl, equals('http://192.168.1.8:5000'));
      expect(ApiConstants.baseUrl, equals('http://192.168.1.8:5000'));
      expect(ApiConstants.connectTimeout, equals(const Duration(seconds: 10)));
      expect(ApiConstants.receiveTimeout, equals(const Duration(seconds: 10)));
      expect(ApiConstants.defaultHeaders['Content-Type'], equals('application/json'));
      expect(ApiConstants.defaultHeaders['Accept'], equals('application/json'));
      expect(ApiEndpoints.adminLogin, equals('/api/v1/auth/adminlogin'));
      expect(ApiEndpoints.operatorLogin, equals('/api/v1/auth/adminlogin'));
    });

    test('2. Dynamic MongoDB response parsing: _id, name, email, role, token and persistence', () async {
      String? capturedMethod;
      String? capturedPath;
      String? capturedContentType;
      String? capturedAccept;
      Map<String, dynamic>? capturedBody;

      final mockHttp = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedContentType = request.headers['Content-Type'];
        capturedAccept = request.headers['Accept'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        // Typical dynamic MongoDB (Node.js/Express) response with _id
        return http.Response(
          jsonEncode({
            'status': 'success',
            'token': 'jwt_mongo_secure_token_98765',
            'user': {
              '_id': '651f8a92c3d4e5f6a7b8c9d0',
              'name': 'Dynamic Operator Khan',
              'email': 'operator.dynamic@cnghub.com',
              'role': 'operator',
              'assignedStation': 'Station Alpha 01',
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuthRepository(client: apiClient);
      final provider = AdminAuthProvider(repository: repo, client: apiClient);

      final user = await provider.operatorLogin('operator.dynamic@cnghub.com', 'mypassword321');

      // Verify request format and payload
      expect(capturedMethod, equals('POST'));
      expect(capturedPath, equals('/api/v1/auth/adminlogin'));
      expect(capturedContentType, contains('application/json'));
      expect(capturedAccept, contains('application/json'));
      expect(capturedBody!['email'], equals('operator.dynamic@cnghub.com'));
      expect(capturedBody!['password'], equals('mypassword321'));

      // Verify dynamic MongoDB user object parsed
      expect(user, isNotNull);
      expect(user!.id, equals('651f8a92c3d4e5f6a7b8c9d0'));
      expect(user.name, equals('Dynamic Operator Khan'));
      expect(user.email, equals('operator.dynamic@cnghub.com'));
      expect(user.role, equals(UserRole.operator));
      expect(user.assignedStation, equals('Station Alpha 01'));

      // Verify provider state updated dynamically (not dummy)
      expect(provider.isLoggedIn, isTrue);
      expect(provider.currentUser?.id, equals('651f8a92c3d4e5f6a7b8c9d0'));
      expect(provider.currentUser?.name, equals('Dynamic Operator Khan'));
      expect(provider.profile.name, equals('Dynamic Operator Khan'));

      // Verify token persisted and attached to client
      expect(apiClient.authToken, equals('jwt_mongo_secure_token_98765'));
      final savedToken = await AuthStorage.instance.getToken();
      expect(savedToken, equals('jwt_mongo_secure_token_98765'));

      // Verify subsequent request automatically includes Bearer token in headers
      String? subsequentAuthHeader;
      final subsequentClient = ApiClient(httpClient: MockClient((req) async {
        subsequentAuthHeader = req.headers['Authorization'];
        return http.Response(jsonEncode([]), 200);
      }));
      subsequentClient.setAuthToken(savedToken);
      await subsequentClient.get('/api/v1/pumps');
      expect(subsequentAuthHeader, equals('Bearer jwt_mongo_secure_token_98765'));
    });

    test('3. ApiException extracts exact backend error message for 400 and 401', () {
      final exc401 = ApiException.fromStatusCode(401, {
        'message': 'Invalid credentials. Password does not match.'
      });
      expect(exc401.message, equals('Invalid credentials. Password does not match.'));

      final excNested = ApiException.fromStatusCode(400, {
        'data': {'message': 'User not found in station database.'}
      });
      expect(excNested.message, equals('User not found in station database.'));
    });

    testWidgets('4. LoginScreen starts clean without hardcoded input values',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify both fields start empty
      final emailControllerFinder = find.byType(TextFormField).at(0);
      final passwordControllerFinder = find.byType(TextFormField).at(1);

      expect((tester.widget(emailControllerFinder) as TextFormField).controller?.text, isEmpty);
      expect((tester.widget(passwordControllerFinder) as TextFormField).controller?.text, isEmpty);
    });

    testWidgets('5. LoginScreen loads saved session credentials only if Remember me was previously checked',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pre-save remember me in storage
      await AuthStorage.instance.saveRememberMe(
        enabled: true,
        email: 'remembered.operator@cnghub.com',
      );

      await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify remembered email is loaded
      final emailField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
      expect(emailField.controller?.text, equals('remembered.operator@cnghub.com'));
    });

    testWidgets('6. Dynamic login reads inputs dynamically and navigates cleanly to OperatorUserScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? capturedEmail;
      String? capturedPassword;

      final mockHttp = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        capturedEmail = body['email']?.toString();
        capturedPassword = body['password']?.toString();

        return http.Response(
          jsonEncode({
            'status': 'success',
            'token': 'jwt_dynamic_token_live',
            'user': {
              '_id': '651abcd1234efgh5678',
              'name': 'Hamza Tariq',
              'email': capturedEmail,
              'role': 'operator',
              'assignedStation': 'Islamabad CNG Station #04',
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuthRepository(client: apiClient);
      final authProvider = AdminAuthProvider(repository: repo, client: apiClient);

      await tester.pumpWidget(
        _buildTestApp(
          home: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Dynamically enter user credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'hamza@cnghub.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'mysecret999');
      await tester.pump();

      // Tap Login button
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify dynamic inputs reached backend
      expect(capturedEmail, equals('hamza@cnghub.com'));
      expect(capturedPassword, equals('mysecret999'));

      // Verify navigation to Operator screen with dynamic MongoDB data
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(OperatorUserScreen), findsOneWidget);
      expect(find.textContaining('Hamza Tariq'), findsOneWidget);
      expect(find.textContaining('Islamabad CNG Station #04'), findsOneWidget);
    });

    testWidgets('7. LoginScreen displays exact backend error message in SnackBar on failure',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Account not active or invalid credentials.',
          }),
          401,
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuthRepository(client: apiClient);
      final authProvider = AdminAuthProvider(repository: repo, client: apiClient);

      await tester.pumpWidget(
        _buildTestApp(
          home: const LoginScreen(),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@cnghub.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'badpassword');
      await tester.pump();

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify still on LoginScreen and exact backend message displayed in SnackBar
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Account not active or invalid credentials.'), findsOneWidget);
    });
  });
}
