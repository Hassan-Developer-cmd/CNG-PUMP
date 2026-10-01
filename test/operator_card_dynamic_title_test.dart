import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/models/cng_user_model.dart';
import 'package:cng_pump/providers/admin_auth_provider.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/screens/dashboard/dashboard_screen.dart';
import 'package:cng_pump/screens/users/operator_user_screen.dart';
import 'package:cng_pump/widgets/dashboard/user_profile_header.dart';

Widget _buildTestApp({
  required Widget child,
  UserProvider? userProvider,
  AdminAuthProvider? authProvider,
  CaptureProvider? captureProvider,
  HistoryProvider? historyProvider,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MultiProvider(
      providers: [
        if (authProvider != null)
          ChangeNotifierProvider.value(value: authProvider)
        else
          ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        if (userProvider != null)
          ChangeNotifierProvider.value(value: userProvider)
        else
          ChangeNotifierProvider(create: (_) => UserProvider()),
        if (captureProvider != null)
          ChangeNotifierProvider.value(value: captureProvider)
        else
          ChangeNotifierProvider(create: (_) => CaptureProvider()),
        if (historyProvider != null)
          ChangeNotifierProvider.value(value: historyProvider)
        else
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => PumpProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('Operator Card Dynamic Title Tests (Removing Hardcoded "Ali")', () {
    testWidgets('UserProfileHeader reads dynamic name from UserProvider and capitalizes first letter', (tester) async {
      final userProvider = UserProvider();
      final captureProvider = CaptureProvider();

      // Log in operator "adnangul"
      userProvider.setCurrentUser(
        CngUser(
          id: 'op_999',
          name: 'adnangul',
          email: 'adnangul@cng.com',
          assignedStation: 'Karachi Central',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        child: const UserProfileHeader(),
        userProvider: userProvider,
        captureProvider: captureProvider,
      ));
      await tester.pumpAndSettle();

      // In initial Meter mode: should show "Adnangul Meter" (NOT "Ali Meter")
      expect(find.text('Adnangul Meter'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);

      // Switch mode to Nozzle 3 -> dynamically updates to "Adnangul Nozzle 3"
      captureProvider.setPrimarySourceMode(PrimarySourceMode.nozzle3);
      await tester.pumpAndSettle();

      expect(find.text('Adnangul Nozzle 3'), findsOneWidget);
      expect(find.text('Adnangul Meter'), findsNothing);
      expect(find.textContaining('Ali'), findsNothing);
    });

    testWidgets('UserProfileHeader reads dynamic operator from AdminAuthProvider when UserProvider is empty', (tester) async {
      final captureProvider = CaptureProvider();
      final authProvider = AdminAuthProvider();

      // Set logged-in operator in AuthProvider
      authProvider.setCurrentUser(
        CngUser(
          id: 'op_888',
          name: 'tariq_jamil',
          email: 'tariq@cng.com',
          assignedStation: 'Lahore Hub',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        child: const UserProfileHeader(),
        authProvider: authProvider,
        captureProvider: captureProvider,
      ));
      await tester.pumpAndSettle();

      // Should display "Tariq_jamil Meter"
      expect(find.text('Tariq_jamil Meter'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);

      // Switch mode to Nozzle 2
      captureProvider.setPrimarySourceMode(PrimarySourceMode.nozzle2);
      await tester.pumpAndSettle();

      expect(find.text('Tariq_jamil Nozzle 2'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);
    });

    testWidgets('DashboardScreen displays dynamic operator name across mode switches without hardcoded "Ali"', (tester) async {
      final userProvider = UserProvider();
      final captureProvider = CaptureProvider();

      userProvider.setCurrentUser(
        CngUser(
          id: 'op_777',
          name: 'adnangul',
          email: 'adnangul@cng.com',
          assignedStation: 'Rawalpindi Hub',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        child: const DashboardScreen(),
        userProvider: userProvider,
        captureProvider: captureProvider,
      ));
      await tester.pumpAndSettle();

      // Dashboard profile card shows "Adnangul Meter"
      expect(find.text('Adnangul Meter'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);

      // Switch to Nozzle 4
      captureProvider.setPrimarySourceMode(PrimarySourceMode.nozzle4);
      await tester.pumpAndSettle();

      expect(find.text('Adnangul Nozzle 4'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);
    });

    testWidgets('OperatorUserScreen shows consistent operator name in top bar and dashboard card', (tester) async {
      final captureProvider = CaptureProvider();

      await tester.pumpWidget(_buildTestApp(
        child: const OperatorUserScreen(
          userName: 'adnangul',
          userId: 'OP-4545',
          stationName: 'Islamabad Express Station',
        ),
        captureProvider: captureProvider,
      ));
      await tester.pumpAndSettle();

      // Top app bar displays "Operator: adnangul (ID: OP-4545)"
      expect(find.text('Operator: adnangul (ID: OP-4545)'), findsOneWidget);

      // Profile banner card displays "Adnangul Meter" (matching dynamic operator, capitalized, mode appended)
      expect(find.text('Adnangul Meter'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);

      // Change mode to Nozzle 1
      captureProvider.setPrimarySourceMode(PrimarySourceMode.nozzle1);
      await tester.pumpAndSettle();

      expect(find.text('Adnangul Nozzle 1'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);
    });

    testWidgets('Fallback: When no user name is available, gracefully falls back to "Operator <mode>"', (tester) async {
      final captureProvider = CaptureProvider();
      final authProvider = AdminAuthProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(_buildTestApp(
        child: const UserProfileHeader(userName: ''),
        captureProvider: captureProvider,
        authProvider: authProvider,
        userProvider: userProvider,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      // If no name is resolved, fallback is Operator
      expect(find.text('Operator Meter'), findsOneWidget);
      expect(find.textContaining('Ali'), findsNothing);
    });
  });
}
