import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';

class ResultDetailsScreen extends StatelessWidget {
  final String dateTitle;
  final String digitalMachineValue;
  final String manualDataValue;
  final String microMotionValue;
  final String suiGasValue;
  final String differenceValue;
  final String thresholdValue;
  final bool hasCorruption;

  const ResultDetailsScreen({
    super.key,
    this.dateTitle = '16/09/2026 - 12:15',
    this.digitalMachineValue = '2,104.50 KG',
    this.manualDataValue = '2,105.85 KG',
    this.microMotionValue = '2,105.85 KG',
    this.suiGasValue = 'Not Provided',
    this.differenceValue = '1.35 KG',
    this.thresholdValue = '1 KG',
    this.hasCorruption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomCurvedAppBar(
        title: 'Result Details',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alert Banner
                    _buildAlertBanner(),
                    SizedBox(height: 16.h),

                    // Details Card
                    _buildDetailsCard(),
                  ],
                ),
              ),
            ),

            // Done Button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corruption Detected',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'The difference between measured readings is more than 1 KG.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF991B1B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text(
              'COMPARISON DETAILS',
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              children: [
                // Row 1: Digital Machine & Sui Gas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Digital Machine',
                        value: digitalMachineValue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Sui Gas',
                        value: suiGasValue,
                        isMuted: suiGasValue == 'Not Provided',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Row 2: Micro Motion
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Micro Motion',
                        value: microMotionValue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Difference Highlight Container
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Difference',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        differenceValue,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Threshold Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Threshold',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      thresholdValue,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    bool isMuted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: isMuted ? FontWeight.w500 : FontWeight.w700,
            color: isMuted ? const Color(0xFF64748B) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
