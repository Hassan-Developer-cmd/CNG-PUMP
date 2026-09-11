import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
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

  Future<void> _openCamera(BuildContext context, int index) async {
    final File? capturedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (capturedFile != null && context.mounted) {
      await context.read<TextComparisonProvider>().setImage(
        index,
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
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
      body: Consumer<TextComparisonProvider>(
        builder: (context, provider, child) {
          final items = provider.readingItems;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Header ("Ali")
                const UserProfileHeader(),
                const SizedBox(height: 16),

                // Nozzle / Meter selector for the primary (first) card
                Align(
                  alignment: Alignment.centerRight,
                  child: SourceSelectorDropdown(
                    selected: provider.primarySourceMode,
                    onChanged: (mode) =>
                        provider.setPrimarySourceMode(mode),
                  ),
                ),
                const SizedBox(height: 8),

                // 4 Reading Cards — the first swaps between the Nozzle
                // (Digital Machine) and Meter image container based on the
                // selector above; the rest stay unchanged.
                ...items.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final item = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CngReadingCard(
                      item: item,
                      onCustomCameraRequested: () =>
                          _openCamera(context, index),
                      onImageCaptured: (file) {
                        provider.setImage(index, file);
                      },
                      onTextChanged: (text) {
                        provider.setText(index, text);
                      },
                    ),
                  );
                }),

                const SizedBox(height: 4),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                // Information Note Banner
                const InfoNoteCard(),
                const SizedBox(height: 20),

                // "Compare Data" Button
                CustomPrimaryButton(
                  text: AppConstants.compareData,
                  icon: Icons.compare_arrows,
                  isEnabled: provider.canCompare,
                  isLoading: provider.isAnyLoading,
                  onPressed: () => _navigateToComparison(context),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
