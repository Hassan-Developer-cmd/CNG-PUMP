import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/capture_provider.dart';
import '../../providers/user_provider.dart';

class UserProfileHeader extends StatelessWidget {
  final String? userName;
  final String? selectedMode;

  const UserProfileHeader({
    super.key,
    this.userName,
    this.selectedMode,
  });

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: 14.w),
          Expanded(
            child: Builder(
              builder: (context) {
                // 1. Resolve providers safely
                UserProvider? userProvider;
                try {
                  userProvider = Provider.of<UserProvider>(context, listen: true);
                } catch (_) {}

                AdminAuthProvider? authProvider;
                try {
                  authProvider = Provider.of<AdminAuthProvider>(context, listen: true);
                } catch (_) {}

                CaptureProvider? captureProvider;
                try {
                  captureProvider = Provider.of<CaptureProvider>(context, listen: true);
                } catch (_) {}

                // 2. Read dynamic operator name directly from UserProvider, AuthState, or session
                String? dynamicOperatorName;

                // Priority A: UserProvider
                final userFromProvider = userProvider?.currentUser;
                if (userFromProvider != null) {
                  final name = userFromProvider.name.isNotEmpty
                      ? userFromProvider.name
                      : userFromProvider.username;
                  if (name.trim().isNotEmpty) {
                    dynamicOperatorName = name.trim();
                  }
                }

                // Priority B: AdminAuthProvider / AuthState
                if (dynamicOperatorName == null || dynamicOperatorName.isEmpty) {
                  final authUser = authProvider?.currentUser;
                  if (authUser != null) {
                    final name = authUser.name.isNotEmpty
                        ? authUser.name
                        : authUser.username;
                    if (name.trim().isNotEmpty) {
                      dynamicOperatorName = name.trim();
                    }
                  } else if (authProvider?.profile.name.isNotEmpty == true &&
                      authProvider!.profile.name.trim() != 'Admin') {
                    dynamicOperatorName = authProvider.profile.name.trim();
                  }
                }

                // Priority C: Explicit userName passed into widget (if not default 'Ali')
                if (dynamicOperatorName == null || dynamicOperatorName.isEmpty) {
                  if (userName != null &&
                      userName!.trim().isNotEmpty &&
                      userName!.trim() != 'Ali' &&
                      userName!.trim() != AppConstants.defaultUserName) {
                    dynamicOperatorName = userName!.trim();
                  }
                }

                // Priority D: CaptureProvider custom operator name
                if (dynamicOperatorName == null || dynamicOperatorName.isEmpty) {
                  if (captureProvider != null && captureProvider.hasCustomOperatorName) {
                    dynamicOperatorName = captureProvider.operatorName;
                  }
                }

                // Priority E: Explicit userName passed into widget (even if default)
                if (dynamicOperatorName == null || dynamicOperatorName.isEmpty) {
                  if (userName != null && userName!.trim().isNotEmpty) {
                    dynamicOperatorName = userName!.trim();
                  }
                }

                // Priority F: Fallback to "Operator"
                if (dynamicOperatorName == null || dynamicOperatorName.isEmpty) {
                  dynamicOperatorName = 'Operator';
                }

                // 3. Capitalize and format name
                final formattedOperator = _capitalize(dynamicOperatorName);
                final modeName = selectedMode ?? captureProvider?.selectedMode ?? '';
                final cleanMode = modeName.trim();

                // 4. Combine dynamically with mode/nozzle
                final String displayName;
                if (cleanMode.isEmpty) {
                  displayName = formattedOperator;
                } else if (formattedOperator.toLowerCase().endsWith(cleanMode.toLowerCase())) {
                  displayName = formattedOperator;
                } else {
                  displayName = '$formattedOperator $cleanMode';
                }

                return Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ) ??
                      TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 46.w,
      height: 46.h,
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.person, color: const Color(0xFF5D4037), size: 28.sp),
      ),
    );
  }
}
