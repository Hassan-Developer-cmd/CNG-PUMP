import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../widgets/dashboard/dashboard_bottom_nav_bar.dart';
import '../../widgets/history/audit_history_card.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch live persistent history from MongoDB on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<HistoryProvider>(context, listen: false).fetchHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomCurvedAppBar(
        title: 'Audit Ledger & History',
        showBackButton: canPop,
        showLogo: !canPop,
        onBackPressed: canPop ? () => Navigator.of(context).pop() : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(
                'Audit Inspection & Logs',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Provider.of<HistoryProvider>(context, listen: false)
                    .fetchHistory(showLoading: false),
                color: AppColors.figmaEmerald,
                child: Consumer<HistoryProvider>(
                  builder: (context, provider, _) {
                    // 1. Loading State
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                        ),
                      );
                    }

              // 2. Error State with Retry Button
              if (provider.errorMessage != null) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: 500.h,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 54.sp,
                          color: const Color(0xFFDC2626),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        ElevatedButton.icon(
                          onPressed: () => Provider.of<HistoryProvider>(context, listen: false)
                              .fetchHistory(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 3. Empty State ("No audit history found in database")
              if (provider.historyList.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: 500.h,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68.w,
                          height: 68.h,
                          decoration: const BoxDecoration(
                            color: AppColors.lightTeal,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 34.sp,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No audit history found in database',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'No audit history found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 4. Populated State: Render dynamic audit cards
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: provider.historyList.length,
                separatorBuilder: (_, __) => SizedBox(height: 14.h),
                itemBuilder: (context, index) {
                  final item = provider.historyList[index];
                  return AuditHistoryCard(item: item);
                },
              );
            },
          ),
        ),
      ),
    ],
  ),
),
      bottomNavigationBar:
          canPop ? null : const DashboardBottomNavBar(currentIndex: 1),
    );
  }
}

/// Dynamic alias for AuditHistoryScreen
typedef AuditHistoryScreen = HistoryScreen;
