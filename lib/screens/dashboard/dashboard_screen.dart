import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/cng_reading_item.dart';
import '../../providers/text_comparison_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../../widgets/shared_widgets/custom_primary_button.dart';
import '../../widgets/shared_widgets/source_selector_dropdown.dart';
import '../../widgets/dashboard/cng_reading_card.dart';
import '../../widgets/dashboard/info_note_card.dart';
import '../../widgets/dashboard/user_profile_header.dart';
import '../camera_screen/camera_screen.dart';
import '../comparing_result/comparing_data_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _openCamera(BuildContext context, CngReadingType type) async {
    final File? capturedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (capturedFile != null && context.mounted) {
      await context.read<TextComparisonProvider>().setImageByType(
        type,
        capturedFile,
      );
    }
  }

  void _navigateToComparison(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComparingDataScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        // APP BAR
        appBar: CustomCurvedAppBar(
          title: AppConstants.appName,
          showLogo: true,
          actions: [
            Consumer<TextComparisonProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Clear All',
                  onPressed: () => provider.clearAll(),
                );
              },
            ),
          ],
        ),

        // BODY
        body: Consumer<TextComparisonProvider>(
          builder: (context, provider, child) {
            final items = provider.readingItems;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // USER PROFILE
                  UserProfileHeader(),
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SourceSelectorDropdown(
                        selected: provider.primarySourceMode,
                        onChanged: provider.setPrimarySourceMode,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // READING CARDS
                  ...items.map((item) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: CngReadingCard(
                        item: item,
                        onCustomCameraRequested: () =>
                            _openCamera(context, item.type),
                        onImageCaptured: (file) =>
                            provider.setImageByType(item.type, file),
                        onTextChanged: (text) =>
                            provider.setTextByType(item.type, text),
                      ),
                    );
                  }),

                  SizedBox(height: 2.h),
                  // DIVIDER
                  Divider(color: AppColors.divider, height: 1),
                  SizedBox(height: 16.h),
                  // INFO NOTE
                  InfoNoteCard(),
                  SizedBox(height: 20.h),
                  // COMPARE BUTTON
                  CustomPrimaryButton(
                    text: AppConstants.compareData,
                    icon: Icons.compare_arrows,
                    isEnabled: provider.canCompare,
                    isLoading: provider.isAnyLoading,
                    onPressed: () => _navigateToComparison(context),
                  ),

                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
