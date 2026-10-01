import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../providers/capture_provider.dart';
import '../../screens/auth/login_screen.dart';

class CustomCurvedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomCurvedAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showLogo = false,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: onBackPressed ??
                      () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          try {
                            final captureProvider =
                                context.read<CaptureProvider>();
                            captureProvider.stopAndRemoveTimer();
                            captureProvider.clearAll();
                          } catch (_) {}
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                )
              else if (showLogo) ...[
                _buildLogo(),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Text(
                  title,
                  style: AppTypography.appBarTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        // color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          // color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Image.asset(AppConstants.appLogo, fit: BoxFit.contain),
    );
  }
}
