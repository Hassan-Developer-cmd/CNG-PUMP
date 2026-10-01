import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import 'comparison_result_screen.dart';

class ComparingResultScreen extends StatefulWidget {
  final VoidCallback? onFinished;
  final CaptureHistoryItem? session;
  final String? sessionId;
  final String digitalMachineValue;
  final String suiGasValue;
  final String rFlowValue;
  final String differenceValue;
  final String thresholdValue;
  final bool hasCorruption;

  const ComparingResultScreen({
    super.key,
    this.onFinished,
    this.session,
    this.sessionId,
    this.digitalMachineValue = '24259.00 KG',
    this.suiGasValue = '24257.65 KG',
    this.rFlowValue = 'Not Provided',
    this.differenceValue = '1.35 KG',
    this.thresholdValue = '1 KG',
    this.hasCorruption = true,
  });

  @override
  State<ComparingResultScreen> createState() => _ComparingResultScreenState();
}

class _ComparingResultScreenState extends State<ComparingResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Automatically navigate to ComparisonResultScreen after 1.8 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _proceedToResult();
      }
    });
  }

  void _proceedToResult() {
    _navigationTimer?.cancel();
    if (widget.onFinished != null) {
      widget.onFinished!();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonResultScreen(
          session: widget.session,
          sessionId: widget.sessionId,
          digitalMachineValue: widget.digitalMachineValue,
          suiGasValue: widget.suiGasValue,
          rFlowValue: widget.rFlowValue,
          differenceValue: widget.differenceValue,
          thresholdValue: widget.thresholdValue,
          hasCorruption: widget.hasCorruption,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomCurvedAppBar(
        title: 'Comparing Data',
        showLogo: true,
      ),
      body: InkWell(
        onTap: _proceedToResult,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12.h),

              // Animated Sync Icon inside Mint Circle
              Container(
                width: 74.w,
                height: 74.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF70C9B6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _animController,
                    child: Icon(
                      Icons.sync_rounded,
                      color: Colors.white,
                      size: 38.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              // Title
              Text(
                'Comparing Your Data',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),

              // Subtitle
              Text(
                'Please wait while we compare the\nsubmitted readings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 28.h),

              // Processing Sources Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROCESSING SOURCES',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _buildSourceRow(
                      title: 'Digital Machine',
                      isCompleted: true,
                    ),
                    SizedBox(height: 10.h),
                    _buildSourceRow(
                      title: 'Micro Motion',
                      isCompleted: true,
                    ),
                    SizedBox(height: 10.h),
                    _buildSourceRow(
                      title: 'Sui Gas',
                      subtitle: 'Analysing parameters...',
                      isCompleted: false,
                      isLoading: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceRow({
    required String title,
    String? subtitle,
    required bool isCompleted,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          if (isCompleted)
            Container(
              width: 22.w,
              height: 22.h,
              decoration: const BoxDecoration(
                color: Color(0xFF56BAA7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 14.sp,
              ),
            )
          else if (isLoading)
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF56BAA7),
              ),
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              size: 20.sp,
              color: AppColors.textMuted,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
