import 'package:cng_pump/constants/app_colors.dart';
import 'package:cng_pump/constants/app_constants.dart';
import 'package:cng_pump/constants/app_typography.dart';
import 'package:cng_pump/screens/main_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Container(
                        height: 200.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.r),
                            bottomRight: Radius.circular(30.r),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppConstants.appLogo,
                                  width: 60.w,
                                  height: 60.h,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  AppConstants.appName,
                                  style: AppTypography.appBarTitle.copyWith(
                                    fontSize: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15.h),
                            Text(
                              'Admin Console',
                              style: AppTypography.infoText.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // WELCOME SECTION
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: AppTypography.loginTitle,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Enter your credentials to access the\n'
                              'management dashboard.',
                              style: AppTypography.loginSubtitle,
                            ),
                          ],
                        ),
                      ),

                      // LOGIN FORM
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // EMAIL LABEL
                            Text(
                              'Email Address',
                              style: AppTypography.inputLabel,
                            ),
                            SizedBox(height: 6.h),

                            // EMAIL FIELD
                            TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              style: AppTypography.inputText,
                              decoration: _inputDecoration(
                                hintText: 'admin@cng-ops.com',
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                            SizedBox(height: 22.h),

                            // PASSWORD LABEL + FORGOT PASSWORD
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password',
                                  style: AppTypography.inputLabel,
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),

                            // PASSWORD FIELD
                            TextFormField(
                              obscureText: _obscurePassword,
                              style: AppTypography.inputText,
                              decoration: _inputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixIconTap: _togglePasswordVisibility,
                              ),
                            ),
                            SizedBox(height: 34.h),

                            // LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MainScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: AppColors.textLight,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  'Login to Dashboard',
                                  style: AppTypography.primaryButton,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // FLEXIBLE SPACE
                      const Spacer(),

                      // FOOTER
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        color: AppColors.headerGray,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 7.w),
                            Text(
                              'Secure admin access only.',
                              style: AppTypography.infoText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // INPUT DECORATION

  static InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.inputHint,
      prefixIcon: Icon(prefixIcon, size: 20.sp, color: AppColors.textMuted),
      suffixIcon: suffixIcon == null
          ? null
          : IconButton(
              icon: Icon(suffixIcon, size: 20.sp, color: AppColors.textMuted),
              onPressed: onSuffixIconTap,
            ),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 1.2),
      ),
    );
  }
}
