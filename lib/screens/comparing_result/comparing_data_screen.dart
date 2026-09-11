import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/history_provider.dart';
import '../../providers/text_comparison_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import 'comparing_result_screen.dart';

class ComparingDataScreen extends StatefulWidget {
  const ComparingDataScreen({super.key});

  @override
  State<ComparingDataScreen> createState() => _ComparingDataScreenState();
}

class _ComparingDataScreenState extends State<ComparingDataScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _completedCount = i + 1);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final provider = context.read<TextComparisonProvider>();
    final result = provider.comparisonResult;
    context.read<HistoryProvider>().addFromResult(result);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ComparingResultScreen()),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingItems = context.watch<TextComparisonProvider>().readingItems;
    final List<String> requiredSourceLabels = [
      readingItems[0].title, // Digital Machine or Meter, per current mode
      readingItems[1].title, // Manual Data
      readingItems[2].title, // Micro Motion
    ];
    final bool suiGasProvided = readingItems[3].hasText;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomCurvedAppBar(
        title: AppConstants.comparingDataTitle,
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          children: [
            RotationTransition(
              turns: _spinController,
              child: Container(
                width: 84.w,
                height: 84.h,
                decoration: const BoxDecoration(
                  color: AppColors.lightTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync,
                  color: AppColors.primaryTeal,
                  size: 36.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              AppConstants.comparingYourData,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppConstants.comparingSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 28.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.headerGray,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15.r),
                      ),
                    ),
                    child: Text(
                      AppConstants.processingSources,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < requiredSourceLabels.length; i++)
                          _SourceRow(
                            label: requiredSourceLabels[i],
                            isDone: i < _completedCount,
                          ),
                        _SourceRow(
                          label: AppConstants.suiGas,
                          isDone: suiGasProvided,
                          subtitleWhenPending: AppConstants.includedIfProvided,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final String? subtitleWhenPending;

  const _SourceRow({
    required this.label,
    required this.isDone,
    this.subtitleWhenPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDone ? Colors.white : AppColors.headerGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primaryTeal : Colors.white,
              shape: BoxShape.circle,
              border: isDone ? null : Border.all(color: AppColors.borderLight),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.hourglass_empty,
              size: 16.sp,
              color: isDone ? Colors.white : AppColors.textMuted,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!isDone && subtitleWhenPending != null)
                  Text(
                    subtitleWhenPending!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
