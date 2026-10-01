import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';
import '../../providers/capture_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';

class ComparisonResultScreen extends StatefulWidget {
  final String digitalMachineValue;
  final String suiGasValue;
  final String rFlowValue;
  final String differenceValue;
  final String thresholdValue;
  final bool hasCorruption;
  final CaptureHistoryItem? session;
  final String? sessionId;

  const ComparisonResultScreen({
    super.key,
    this.digitalMachineValue = '24259.00 KG',
    this.suiGasValue = '24257.65 KG',
    this.rFlowValue = 'Not Provided',
    this.differenceValue = '1.35 KG',
    this.thresholdValue = '1 KG',
    this.hasCorruption = true,
    this.session,
    this.sessionId,
  });

  @override
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
  bool _isLoading = false;

  Future<void> _handleDone() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final captureProvider = context.read<CaptureProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final sid = widget.sessionId ??
        widget.session?.id ??
        captureProvider.activeSessionId ??
        'aud_${DateTime.now().millisecondsSinceEpoch}';

    final success = await captureProvider.completeSession(
      sessionId: sid,
      difference: widget.differenceValue,
      threshold: widget.thresholdValue,
      hasCorruption: widget.hasCorruption,
      statusText: widget.hasCorruption ? 'CORRUPTION_DETECTED' : 'IN_SYNC',
    );

    if (!mounted) return;

    if (success) {
      // 1. If a local session record was created, push it to history provider
      if (widget.session != null) {
        historyProvider.addSession(widget.session!);
      }

      // 2. Dynamically refresh the History list from backend
      await historyProvider.fetchHistory();

      // 3. Safely reset the local audit session and timer in CaptureProvider
      captureProvider.clearAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
          content: Text(
            'Audit capture successfully completed and recorded.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      // 4. Navigate back to the home/dashboard screen
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      setState(() => _isLoading = false);
      final errorMsg = captureProvider.completionError ??
          'Failed to complete audit session. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
          content: Text(
            errorMsg,
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleDone,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomCurvedAppBar(
        title: 'Comparison Result',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner: Corruption Detected (or In-Sync)
                        _buildStatusBanner(),
                        SizedBox(height: 16.h),

                        // Comparison Details Card
                        _buildComparisonCard(),
                      ],
                    ),
                  ),
                ),

                // Bottom "Done" Button with Loading Spinner
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        disabledBackgroundColor:
                            AppColors.primaryTeal.withValues(alpha: 0.65),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 22.h,
                              height: 22.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
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

            // Loading Overlay during transmission
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'Completing audit session...',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
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

  Widget _buildStatusBanner() {
    final isCorruption = widget.hasCorruption;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isCorruption ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isCorruption ? const Color(0xFFFECACA) : const Color(0xFFC8E6C9),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: isCorruption ? const Color(0xFFDC2626) : const Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorruption ? Icons.warning_amber_rounded : Icons.check_circle_outline,
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
                  isCorruption ? 'Corruption Detected' : 'Readings In-Sync',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isCorruption ? const Color(0xFFB91C1C) : const Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  isCorruption
                      ? 'Discrepancy detected between compared readings across sources.'
                      : 'All readings match within the acceptable threshold.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isCorruption ? const Color(0xFF991B1B) : const Color(0xFF2E7D32),
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

  Widget _buildComparisonCard() {
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
                        value: widget.digitalMachineValue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Sui Gas',
                        value: widget.suiGasValue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Row 2: R Flow
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        label: 'R Flow',
                        value: widget.rFlowValue,
                        isMuted: true,
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
                    color: widget.hasCorruption
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFF0FDF4),
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
                        widget.differenceValue,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: widget.hasCorruption
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
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
                      widget.thresholdValue,
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
