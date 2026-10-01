import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../models/cng_reading_item.dart';
import '../../providers/capture_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/pump_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../../widgets/shared_widgets/custom_primary_button.dart';
import '../../widgets/shared_widgets/source_selector_dropdown.dart';
import '../../widgets/shared_widgets/status_badge.dart';
import '../../widgets/dashboard/dashboard_bottom_nav_bar.dart';
import '../../widgets/dashboard/info_note_card.dart';
import '../../widgets/dashboard/reading_picture_box.dart';
import '../../widgets/dashboard/user_profile_header.dart';
import '../auth/login_screen.dart';
import '../camera_screen/camera_screen.dart';
import '../../services/api/api_exception.dart';

String dropdowntext = "Dummy";

class DashboardScreen extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? operatorName;

  const DashboardScreen({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.operatorName,
  });

  void _handleBackToLogin(BuildContext context) {
    try {
      final captureProvider = context.read<CaptureProvider>();
      captureProvider.stopAndRemoveTimer();
      captureProvider.clearAll();
    } catch (_) {}

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openCamera(
    BuildContext context,
    CngReadingType type,
    String title,
  ) async {
    final CameraCaptureResult? result =
        await Navigator.push<CameraCaptureResult>(
          context,
          MaterialPageRoute(builder: (context) => CameraScreen(title: title)),
        );

    if (result != null && context.mounted) {
      final captureProvider = context.read<CaptureProvider>();
      await captureProvider.setImageByType(
        type,
        result.image,
        result.capturedAt,
      );

      // Immediately upload the freshly captured image in the background.
      // Upload errors surface via cardUploadError and a SnackBar below.
      if (context.mounted) {
        _triggerUpload(context, type);
      }
    }
  }

  /// Fires an upload for [type] and shows a SnackBar if it fails.
  void _triggerUpload(BuildContext context, CngReadingType type) {
    final captureProvider = context.read<CaptureProvider>();
    captureProvider.uploadImageForType(type).then((result) {
      if (result == null || !result.success) {
        if (context.mounted) {
          _showUploadErrorSnackBar(
            context,
            type,
            result?.message ?? 'Image upload failed. Tap Retry to try again.',
          );
        }
      }
    }).catchError((e) {
      if (context.mounted) {
        _showUploadErrorSnackBar(
          context,
          type,
          e.toString(),
        );
      }
    });
  }

  /// Shows a persistent error SnackBar with a Retry action for [type].
  void _showUploadErrorSnackBar(
    BuildContext context,
    CngReadingType type,
    String errorMsg,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB00020),
        content: Text(
          'Upload error: $errorMsg',
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _triggerUpload(context, type),
        ),
      ),
    );
  }

  Future<void> _handleSaveData(BuildContext context) async {
    final captureProvider = context.read<CaptureProvider>();
    final historyProvider = context.read<HistoryProvider>();

    // Step A: Verify all required images for the current mode are captured locally
    // (vb1 + vs1 for Meter, or digitalMachine + counter for Nozzle).
    final isMeterMode = captureProvider.primarySourceMode == PrimarySourceMode.meter;
    if (!captureProvider.hasRequiredImagesCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          content: Text(
            isMeterMode
                ? 'Please capture all required images (VB1 and VS1) before saving.'
                : 'Please capture all required images (Digital Machine and Counter) before saving.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    String stationName = captureProvider.stationName;
    try {
      final pumpProvider = context.read<PumpProvider>();
      if (pumpProvider.allStations.isNotEmpty) {
        stationName = pumpProvider.allStations.first.name;
      }
    } catch (_) {}

    String operatorName = captureProvider.operatorName;
    try {
      final userProvider = context.read<UserProvider>();
      if (userProvider.allUsers.isNotEmpty) {
        operatorName = userProvider.allUsers.first.name;
      }
    } catch (_) {}

    // 1. Stop and remove countdown timer
    captureProvider.stopAndRemoveTimer();

    // Step B: Show a blocking loading dialog or spinner ("Saving and uploading data...")
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Text(
                    'Saving and uploading data...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    bool isProgressOpen = true;
    void closeProgress() {
      if (isProgressOpen && context.mounted) {
        isProgressOpen = false;
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
    }

    try {
      // Step C: Ensure individual images are uploaded first via /captureImage
      await captureProvider.batchUploadAll();

      if (captureProvider.hasCardUploadErrors) {
        closeProgress();
        if (!context.mounted) return;
        final uploadError = captureProvider.firstCardUploadError ??
            'Image upload failed. Tap Retry to try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 6),
            content: Text(
              uploadError,
              style: const TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleSaveData(context),
            ),
          ),
        );
        return;
      }

      // Create active session record
      final newSession = captureProvider.createSessionRecord(
        stationName: stationName,
        operatorName: operatorName,
      );

      final currentCaptureId = captureProvider.activeCaptureId ?? newSession.id;

      // Directly trigger the complete endpoint:
      // POST http://192.168.1.8:5000/api/v1/capture/complete/$currentCaptureId
      final success = await captureProvider.completeSession(
        sessionId: currentCaptureId,
      );

      closeProgress();

      if (success) {
        // Post-Success Actions:
        // Clear the active capture state in CaptureProvider
        captureProvider.clearAll();

        // Refresh HistoryProvider dynamically so the new record appears in history
        historyProvider.addSession(newSession);
        try {
          await historyProvider.fetchHistory();
        } catch (_) {}

        if (!context.mounted) return;

        // Show SnackBar/Toast: "Pics sent successfully"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10.w),
                const Expanded(
                  child: Text(
                    'Pics sent successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Navigate straight back to the Home/Dashboard screen (do not open any Comparison or Done screen)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        if (!context.mounted) return;
        final errorMsg = captureProvider.completionError ??
            'Failed to save and upload data. Tap Retry to try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 6),
            content: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleSaveData(context),
            ),
          ),
        );
      }
    } catch (e) {
      closeProgress();
      if (context.mounted) {
        final errorMsg = e is ApiException
            ? e.message
            : (e.toString().startsWith('Exception: ')
                ? e.toString().substring(11)
                : e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 6),
            content: Text(
              'Upload error: $errorMsg',
              style: const TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleSaveData(context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (onBackPressed != null) {
          onBackPressed!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          _handleBackToLogin(context);
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: CustomCurvedAppBar(
            title: AppConstants.appName,
            showLogo: !showBackButton,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed ?? () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                _handleBackToLogin(context);
              }
            },
            actions: [
              Consumer<CaptureProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Clear All',
                    onPressed: provider.clearAll,
                  );
                },
              ),
            ],
          ),
        body: Consumer<CaptureProvider>(
          builder: (context, provider, child) {
            final isMeterMode =
                provider.primarySourceMode == PrimarySourceMode.meter;
            final primaryTitle = provider.selectedMode;

            final vb1Item = provider.getItemByType(CngReadingType.vb1);
            final vs1Item = provider.getItemByType(CngReadingType.vs1);
            final rFlowItem = provider.getItemByType(CngReadingType.rFlow);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. User Profile Card
                  UserProfileHeader(
                    userName: operatorName ?? provider.operatorName,
                    selectedMode: provider.selectedMode,
                  ),
                  SizedBox(height: 14.h),

                  // 2. Select Nozzle Dropdown (Mint green pill button + popover)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SourceSelectorDropdown(
                        selected: provider.primarySourceMode,
                        onChanged: provider.setPrimarySourceMode,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Optional Timer Banner (if active)
                  if (provider.isTimerVisible) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 9.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightTeal,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18.sp,
                            color: AppColors.primaryTeal,
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: Text(
                              'Take the next picture within 2 minutes',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            provider.formattedRemainingTime,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  if (!isMeterMode) ...[
                    // 1. Meter Card - REQUIRED
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'Meter',
                            icon: Icons.speed_outlined,
                            trailing: const StatusBadge(isRequired: true),
                          ),
                          SizedBox(height: 12.h),
                          ReadingPictureBox(
                            image: provider.meterImage,
                            capturedAt: provider.meterCapturedAt,
                            borderColor: AppColors.dashedRed,
                            label: AppConstants.takePicture,
                            isUploading: provider.isCardUploading(CngReadingType.meter),
                            isVerified: provider.isCardVerified(CngReadingType.meter),
                            uploadError: provider.cardUploadError(CngReadingType.meter),
                            onTap: () => _openCamera(
                              context,
                              CngReadingType.meter,
                              'Meter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // 2. Counter Card - REQUIRED
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'Counter',
                            icon: Icons.av_timer_outlined,
                            trailing: const StatusBadge(isRequired: true),
                          ),
                          SizedBox(height: 12.h),
                          ReadingPictureBox(
                            image: provider.counterImage,
                            capturedAt: provider.counterCapturedAt,
                            borderColor: AppColors.dashedRed,
                            isUploading: provider.isCardUploading(CngReadingType.counter),
                            isVerified: provider.isCardVerified(CngReadingType.counter),
                            uploadError: provider.cardUploadError(CngReadingType.counter),
                            onTap: () => _openCamera(
                              context,
                              CngReadingType.counter,
                              'Counter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // 3. Micro Motion Card - OPTIONAL
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            title: 'Micro Motion',
                            icon: Icons.graphic_eq_rounded,
                            trailing: const StatusBadge(isRequired: false),
                          ),
                          SizedBox(height: 12.h),
                          ReadingPictureBox(
                            image: provider.microMotionImage,
                            capturedAt: provider.microMotionCapturedAt,
                            borderColor: AppColors.dashedGreen,
                            isUploading: provider.isCardUploading(CngReadingType.microMotion),
                            isVerified: provider.isCardVerified(CngReadingType.microMotion),
                            uploadError: provider.cardUploadError(CngReadingType.microMotion),
                            onTap: () => _openCamera(
                              context,
                              CngReadingType.microMotion,
                              'Micro Motion',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                  ] else ...[
                    // In Meter mode: displays VB1, VS1, and R Flow reading picture boxes
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sub-item 1: VB1 (REQUIRED)
                          _buildSubItemRow('VB1', isRequired: true),
                          ReadingPictureBox(
                            image: vb1Item.image,
                            capturedAt: vb1Item.capturedAt,
                            borderColor: AppColors.dashedGreen,
                            height: 75.h,
                            isUploading: provider.isCardUploading(CngReadingType.vb1),
                            isVerified: provider.isCardVerified(CngReadingType.vb1),
                            uploadError: provider.cardUploadError(CngReadingType.vb1),
                            onTap: () =>
                                _openCamera(context, CngReadingType.vb1, 'VB1'),
                          ),
                          SizedBox(height: 10.h),

                          // Sub-item 2: VS1 (REQUIRED)
                          _buildSubItemRow('VS1', isRequired: true),
                          ReadingPictureBox(
                            image: vs1Item.image,
                            capturedAt: vs1Item.capturedAt,
                            borderColor: AppColors.dashedGreen,
                            height: 75.h,
                            isUploading: provider.isCardUploading(CngReadingType.vs1),
                            isVerified: provider.isCardVerified(CngReadingType.vs1),
                            uploadError: provider.cardUploadError(CngReadingType.vs1),
                            onTap: () =>
                                _openCamera(context, CngReadingType.vs1, 'VS1'),
                          ),
                          SizedBox(height: 10.h),

                          // Sub-item 3: R Flow (OPTIONAL)
                          _buildSubItemRow('R Flow', isRequired: false),
                          ReadingPictureBox(
                            image: rFlowItem.image,
                            capturedAt: rFlowItem.capturedAt,
                            borderColor: AppColors.dashedGreen,
                            height: 75.h,
                            isUploading: provider.isCardUploading(CngReadingType.rFlow),
                            isVerified: provider.isCardVerified(CngReadingType.rFlow),
                            uploadError: provider.cardUploadError(CngReadingType.rFlow),
                            onTap: () => _openCamera(
                              context,
                              CngReadingType.rFlow,
                              'R Flow',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                  ],

                  // Bottom Informational Note
                  InfoNoteCard(
                    text: isMeterMode
                        ? provider.suiGasBottomNote
                        : provider.formatBottomNote(primaryTitle),
                  ),
                  SizedBox(height: 18.h),

                  // 8. Save Data Button
                  CustomPrimaryButton(
                    text: AppConstants.saveData,
                    icon: Icons.check_circle_outline_rounded,
                    isEnabled: provider.canViewResult,
                    onPressed: () => _handleSaveData(context),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const DashboardBottomNavBar(),
      ),
    ),
  );
}

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: AppColors.lightTeal,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primaryTeal),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildSubItemRow(String label, {required bool isRequired}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFF56BAA7),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StatusBadge(isRequired: isRequired),
        ],
      ),
    );
  }
}
