import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match!'),
          backgroundColor: AppColors.logoutRed,
        ),
      );
      return;
    }

    final success = await context.read<AdminAuthProvider>().updatePassword(
          _currentPassController.text,
          _newPassController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppColors.figmaEmerald,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password is incorrect!'),
          backgroundColor: AppColors.logoutRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.figmaDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Current Password
              _buildFieldLabel('Current Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _currentPassController,
                obscureText: _obscureCurrent,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Please enter current password' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _passwordDecoration(
                  hint: '••••••••',
                  isObscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              const SizedBox(height: 18),

              // New Password
              _buildFieldLabel('New Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newPassController,
                obscureText: _obscureNew,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter new password';
                  if (val.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _passwordDecoration(
                  hint: '••••••••',
                  isObscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 18),

              // Confirm New Password
              _buildFieldLabel('Confirm New Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPassController,
                obscureText: _obscureConfirm,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Please confirm new password' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _passwordDecoration(
                  hint: '••••••••',
                  isObscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 36),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitUpdate,
                  icon: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                  label: const Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.figmaPrimaryBtn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      suffixIcon: IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.figmaEmerald, width: 1.5),
      ),
    );
  }
}
