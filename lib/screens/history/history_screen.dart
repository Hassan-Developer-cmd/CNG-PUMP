import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/history_provider.dart';
import '../../widgets/history/history_card.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../result_screen/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _pageSize = 5;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomCurvedAppBar(
        title: AppConstants.appName,
        showLogo: true,
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          final records = historyProvider.records;

          if (records.isEmpty) return _buildEmptyState();

          final visibleRecords = records.take(_visibleCount).toList();
          final hasMore = _visibleCount < records.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.historyTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConstants.historySubtitle,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...visibleRecords.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: HistoryCard(
                      record: record,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(historyRecord: record),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasMore)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _visibleCount += _pageSize),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.headerGray,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        AppConstants.loadMoreRecords,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.lightTeal, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, size: 34, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 18),
            const Text(
              AppConstants.noHistoryYet,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.noHistorySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
