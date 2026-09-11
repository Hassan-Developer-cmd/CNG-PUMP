import 'package:cng_pump/constants/app_colors.dart';
import 'package:cng_pump/constants/app_constants.dart';
import 'package:cng_pump/constants/app_typography.dart';
import 'package:flutter/material.dart';

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
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
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppConstants.appName,
                          style: AppTypography.appBarTitle.copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
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
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back', style: AppTypography.loginTitle),
                    SizedBox(height: 6),
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EMAIL LABEL
                    Text('Email Address', style: AppTypography.inputLabel),
                    SizedBox(height: 6),
                    // EMAIL FIELD
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      style: AppTypography.inputText,
                      decoration: _inputDecoration(
                        hintText: 'admin@cng-ops.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    SizedBox(height: 22),
                    // PASSWORD LABEL + FORGOT PASSWORD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password', style: AppTypography.inputLabel),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
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
                    SizedBox(height: 34),
                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.textLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
              SizedBox(height: 40),
              // FOOTER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppColors.headerGray,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 7),
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
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textMuted),
      suffixIcon: suffixIcon == null
          ? null
          : IconButton(
              icon: Icon(suffixIcon, size: 20, color: AppColors.textMuted),
              onPressed: onSuffixIconTap,
            ),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.2),
      ),
    );
  }
}
