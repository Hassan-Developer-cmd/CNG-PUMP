import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../widgets/dashboard/dashboard_bottom_nav_bar.dart';
import '../../widgets/history/audit_session_card.dart';
import '../../widgets/shared_widgets/async_state_view.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import 'admin_audit_detail_screen.dart';
import 'audit_photo_fullscreen_viewer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryProvider>().fetchHistory();
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
        child: RefreshIndicator(
          onRefresh: () => context.read<HistoryProvider>().fetchHistory(),
          color: AppColors.figmaEmerald,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Minimal Screen Header (Title only, no subtitle, no filter chips, no tab switchers)
                Text(
                  'Audit Inspection & Logs',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 14.h),

                // Visual Photo Feed of Audit Sessions
                _buildVisualPhotoFeed(),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          canPop ? null : const DashboardBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildVisualPhotoFeed() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        final sessions = provider.auditSessions;

        return AsyncStateView(
          status: provider.isLoading
              ? AsyncStatus.loading
              : provider.hasError
                  ? AsyncStatus.error
                  : sessions.isEmpty
                      ? AsyncStatus.empty
                      : AsyncStatus.loaded,
          errorMessage: provider.errorMessage,
          emptyTitle: 'No audit history found',
          emptySubtitle:
              'Live operator audit sessions and captured photos will appear here in real-time.',
          emptyIcon: Icons.photo_library_outlined,
          onRetry: provider.fetchHistory,
          child: Column(
            children: [
              for (int i = 0; i < sessions.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: AuditSessionCard(
                    session: sessions[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminAuditDetailScreen(session: sessions[i]),
                        ),
                      );
                    },
                    onImageTap: (imgIndex) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuditPhotoFullscreenViewer(
                            images: sessions[i].images,
                            initialIndex: imgIndex,
                            stationName: sessions[i].stationName,
                            operatorName: sessions[i].operatorName,
                            modeName: sessions[i].modeName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dynamic alias for AuditHistoryScreen
typedef AuditHistoryScreen = HistoryScreen;
