import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/capture_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class OperatorUserScreen extends StatelessWidget {
  final String userName;
  final String userId;
  final String stationName;

  const OperatorUserScreen({
    super.key,
    this.userName = 'Ali Khan',
    this.userId = '7890',
    this.stationName = 'Main CNG Station',
  });

  void _handleBackToLogin(BuildContext context) {
    // 1. Safely cancel any running 120-second countdown timer and reset active capture session
    try {
      final captureProvider = context.read<CaptureProvider>();
      captureProvider.stopAndRemoveTimer();
      captureProvider.clearAll();
    } catch (_) {}

    // 2. Cleanly clear the navigation history and navigate back to LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final capture = Provider.of<CaptureProvider>(context, listen: false);
        if (capture.operatorName != userName) {
          capture.setOperatorName(userName);
        }
      } catch (_) {}
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          color: AppColors.figmaDarkGreen,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Image.asset(
                    AppConstants.appLogo,
                    width: 34,
                    height: 34,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_gas_station_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Operator: $userName (ID: $userId)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Return to Login',
                    onPressed: () => _handleBackToLogin(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackToLogin(context);
        },
        child: Column(
          children: [
            // Station Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.lightTeal,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.figmaEmerald),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assigned Station: $stationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Embedded Dashboard Screen for Taking Readings
            Expanded(
              child: DashboardScreen(operatorName: userName),
            ),
          ],
        ),
      ),
    );
  }
}
