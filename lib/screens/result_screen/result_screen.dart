import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/cng_reading_item.dart';
import '../../models/capture_history_item.dart';
import '../../providers/capture_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../../widgets/shared_widgets/custom_primary_button.dart';

/// Displays the pictures captured on the dashboard.
/// No OCR, text extraction, numerical comparison or difference calculation
/// is performed on this screen.
class ResultScreen extends StatelessWidget {
  final CaptureHistoryItem? historyRecord;

  const ResultScreen({super.key, this.historyRecord});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomCurvedAppBar(
        title: AppConstants.resultTitle,
        showBackButton: true,
      ),
      body: Consumer<CaptureProvider>(
        builder: (context, provider, child) {
          final items = historyRecord == null
              ? provider.readingItems.where((item) => item.hasImage).toList()
              : historyRecord!.images
                  .map((captured) => CngReadingItem(
                        type: CngReadingType.digitalMachine,
                        title: captured.label,
                        isRequired: false,
                        icon: Icons.image_outlined,
                        image: captured.image,
                        inputData: captured.inputData,
                      ))
                  .toList();

          return Column(
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          );
        },
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
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFD),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 10.sp, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '${AppConstants.inputData}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: item.inputData.isEmpty ? AppConstants.notProvided : item.inputData),
                ],
              ),
            ),
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
