import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/cng_user_model.dart';
import '../../providers/pump_provider.dart';
import '../../providers/user_provider.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.operator;
  String? _selectedStation;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final stations = context.read<PumpProvider>().allStations;
    if (stations.isNotEmpty) {
      _selectedStation = stations.first.name;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newUser = CngUser(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      assignedStation: _selectedStation ?? 'Main CNG Station',
      isActive: _isActive,
      createdAt: DateTime.now(),
    );

    context.read<UserProvider>().addUser(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User "${newUser.name}" (ID: ${newUser.id}) added!'),
        backgroundColor: AppColors.figmaEmerald,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<PumpProvider>().allStations;

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
          'Add New User',
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
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'User Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),

              // User ID
              _buildFieldLabel('User ID (e.g. 7899)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter User ID' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Enter numeric ID e.g. 7899',
                  prefixIcon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              _buildFieldLabel('Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter user name' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 16),

              // Email Address
              _buildFieldLabel('Email Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter email' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'user@cnghub.com',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number
              _buildFieldLabel('Phone Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: '+92 300 1234567',
                  prefixIcon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Role
              _buildFieldLabel('Role'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.displayName,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assigned Station
              _buildFieldLabel('Assigned CNG Station'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStation,
                    isExpanded: true,
                    hint: const Text('Select station'),
                    items: stations.map((s) {
                      return DropdownMenuItem(
                        value: s.name,
                        child: Text(
                          s.name,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStation = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active User Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeThumbColor: AppColors.figmaEmerald,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Add User',
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
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary) : null,
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
