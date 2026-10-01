import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cng_pump/config/app_dependencies.dart';
import 'package:cng_pump/screens/auth/login_screen.dart';
import 'package:cng_pump/screens/auth/admin_login_screen.dart';
import 'package:cng_pump/screens/dashboard/admin_dashboard_screen.dart';
import 'package:cng_pump/screens/users/operator_user_screen.dart';
import 'package:cng_pump/constants/app_constants.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';

Widget _buildTestApp({required Widget home}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
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
  setUp(() {
    AppDependencies.initialize(useMock: true);
  });

  testWidgets(
      'Auth Flow: User Login -> Login as Admin -> Admin Login -> Admin Dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Build User Login Screen (default starting screen)
    await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
    await tester.pumpAndSettle();

    // Verify User Login UI elements
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.userLoginSubtitle), findsOneWidget);
    expect(find.text('Operator ID or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text(AppConstants.loginAsAdmin), findsOneWidget);

    // 2. Tap "Login as Admin"
    await tester.tap(find.text(AppConstants.loginAsAdmin));
    await tester.pumpAndSettle();

    // Verify Admin Login screen is shown
    expect(find.byType(AdminLoginScreen), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);
    expect(find.text('ADMIN ACCESS ONLY'), findsOneWidget);
    expect(find.text('Admin Email or ID'), findsOneWidget);
    expect(find.text('Enter Admin Dashboard'), findsOneWidget);
    expect(find.text(AppConstants.backToUserLogin), findsOneWidget);

    // Test back button to User Login
    await tester.tap(find.text(AppConstants.backToUserLogin));
    await tester.pumpAndSettle();

    // Verify returned to User Login
    expect(find.byType(LoginScreen), findsOneWidget);

    // Navigate to Admin Login again
    await tester.tap(find.text(AppConstants.loginAsAdmin));
    await tester.pumpAndSettle();
    expect(find.byType(AdminLoginScreen), findsOneWidget);

    // 3. Enter admin credentials and tap "Enter Admin Dashboard" button on Admin Login
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@cnghub.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin');
    await tester.pump();

    await tester.tap(find.text('Enter Admin Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify Admin Dashboard is displayed
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Total Pumps'), findsOneWidget);
    expect(find.text("Today's Audits"), findsNothing);
    expect(find.text('Active Staff'), findsNothing);
    expect(find.text('STATION MANAGEMENT'), findsNothing);
    expect(find.text('Pumps & Dispensers'), findsNothing);
    expect(find.text('Audit History & Logs'), findsNothing);
    expect(find.text('Operators & Staff'), findsNothing);
    expect(find.text('LIVE AUDIT FEED'), findsOneWidget);
  });

  testWidgets('User Login dummy navigation navigates to Operator screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
    await tester.pumpAndSettle();

    // Enter operator credentials
    await tester.enterText(find.byType(TextFormField).at(0), '7890');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pump();

    // Tap Login button
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify navigates to Operator screen with station and user
    expect(find.textContaining('Operator: Ali Khan'), findsOneWidget);
    expect(find.textContaining('Assigned Station: Main CNG Station #01'), findsOneWidget);

    // Tap the top navigation back arrow
    final backArrowFinder = find.byTooltip('Return to Login');
    expect(backArrowFinder, findsOneWidget);
    await tester.tap(backArrowFinder);
    await tester.pumpAndSettle();

    // Verify cleanly redirected to LoginScreen with navigation stack cleared
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
  });

  testWidgets(
      'Operator screen top back button safely cancels timer and clears capture session',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    final captureProvider = CaptureProvider();
    // Simulate active timer
    captureProvider.setCounterImage(
      File('dummy.jpg'),
      DateTime.now(),
    );

    // Build test app with custom provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
          ChangeNotifierProvider(create: (_) => PumpProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: captureProvider),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => const MaterialApp(
            home: OperatorUserScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap top navigation back arrow
    await tester.tap(find.byTooltip('Return to Login'));
    await tester.pumpAndSettle();

    // Verify redirected to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    // Verify capture timer stopped and capture state cleared
    expect(captureProvider.timerActive, isFalse);
    expect(captureProvider.primaryCardImage, isNull);
    expect(captureProvider.meterImage, isNull);
  });
}

