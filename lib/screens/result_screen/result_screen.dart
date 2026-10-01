import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/cng_reading_item.dart';
import '../../models/capture_history_item.dart';
import '../../providers/capture_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/image_timestamp_service.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../../widgets/shared_widgets/custom_primary_button.dart';

/// Displays the pictures captured on the dashboard.
/// No OCR, text extraction, numerical comparison or difference calculation
/// is performed on this screen.
class ResultScreen extends StatefulWidget {
  final CaptureHistoryItem? historyRecord;

  const ResultScreen({super.key, this.historyRecord});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;

  Future<void> _handleDone() async {
    if (widget.historyRecord != null) {
      Navigator.of(context).pop();
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final captureProvider = context.read<CaptureProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final sid = captureProvider.activeSessionId ??
        'aud_${DateTime.now().millisecondsSinceEpoch}';

    final success = await captureProvider.completeSession(
      sessionId: sid,
      statusText: 'IN_SYNC',
    );

    if (!mounted) return;

    if (success) {
      await historyProvider.fetchHistory();
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: const CustomCurvedAppBar(
          title: AppConstants.resultTitle,
          showBackButton: true,
        ),
        body: Consumer<CaptureProvider>(
          builder: (context, provider, child) {
            final List<CngReadingItem> items;
            if (widget.historyRecord != null) {
              items = widget.historyRecord!.images
                  .map((captured) => CngReadingItem(
                        type: CngReadingType.digitalMachine,
                        title: captured.label,
                        isRequired: false,
                        icon: captured.label.toLowerCase().contains('nozzle')
                            ? Icons.local_gas_station_outlined
                            : (captured.label.toLowerCase().contains('counter')
                                ? Icons.av_timer_outlined
                                : (captured.label.toLowerCase().contains('micro')
                                    ? Icons.graphic_eq_rounded
                                    : Icons.speed_outlined)),
                        image: captured.image,
                        capturedAt: captured.capturedAt,
                      ))
                  .toList();
            } else {
              items = [];
              for (final item in provider.currentReadingItems) {
                if (item.hasImage) items.add(item);
              }
              if (provider.primarySourceMode != PrimarySourceMode.meter) {
                if (!items.any((i) => i.type == CngReadingType.meter) &&
                    provider.meterImage != null) {
                  items.add(CngReadingItem(
                    type: CngReadingType.meter,
                    title: 'Meter',
                    isRequired: false,
                    icon: Icons.speed_outlined,
                    image: provider.meterImage,
                    capturedAt: provider.meterCapturedAt,
                  ));
                }
                if (!items.any((i) => i.type == CngReadingType.counter) &&
                    provider.counterImage != null) {
                  items.add(CngReadingItem(
                    type: CngReadingType.counter,
                    title: 'Counter',
                    isRequired: false,
                    icon: Icons.av_timer_outlined,
                    image: provider.counterImage,
                    capturedAt: provider.counterCapturedAt,
                  ));
                }
                if (!items.any((i) => i.type == CngReadingType.microMotion) &&
                    provider.microMotionImage != null) {
                  items.add(CngReadingItem(
                    type: CngReadingType.microMotion,
                    title: 'Micro Motion',
                    isRequired: false,
                    icon: Icons.graphic_eq_rounded,
                    image: provider.microMotionImage,
                    capturedAt: provider.microMotionCapturedAt,
                  ));
                }
              }
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppConstants.capturedPictures,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              AppConstants.resultSubtitle,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 18.h),
                            ...items.map(
                              (item) => Padding(
                                padding: EdgeInsets.only(bottom: 14.h),
                                child: _ResultImageCard(item: item),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: CustomPrimaryButton(
                          text: AppConstants.done,
                          isLoading: _isLoading,
                          onPressed: _handleDone,
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
            );
          },
        ),
      ),
    );
  }
}

class _ResultImageCard extends StatelessWidget {
  final CngReadingItem item;

  const _ResultImageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final File image = item.image!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  item.icon,
                  size: 17.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.title.toLowerCase().contains('nozzle')) ...[
                      SizedBox(height: 2.h),
                      Builder(
                        builder: (ctx) {
                          final opName = ctx.read<CaptureProvider>().operatorName;
                          return Text(
                            '$opName took this pic from ${item.title}',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (item.capturedAt != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: AppColors.primaryTeal,
                        size: 10.sp,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        ImageTimestampService.formatTimestamp(item.capturedAt!),
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.file(
              image,
              width: double.infinity,
              height: 190.h,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
