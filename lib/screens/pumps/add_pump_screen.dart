import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/pump_station_model.dart';
import '../../providers/pump_provider.dart';
import 'pump_added_success_screen.dart';

class AddPumpScreen extends StatefulWidget {
  const AddPumpScreen({super.key});

  @override
  State<AddPumpScreen> createState() => _AddPumpScreenState();
}

class _AddPumpScreenState extends State<AddPumpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _totalPumpsController = TextEditingController(text: '4');
  final TextEditingController _userIdsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PumpStatus _selectedStatus = PumpStatus.active;

  bool _catFuelPump = true;
  bool _catVehicle = false;
  bool _catMeter = false;
  bool _catOther = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _totalPumpsController.dispose();
    _userIdsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final categories = <String>[];
    if (_catFuelPump) categories.add(AppConstants.catFuelPump);
    if (_catVehicle) categories.add(AppConstants.catVehicle);
    if (_catMeter) categories.add(AppConstants.catMeter);
    if (_catOther) categories.add(AppConstants.catOther);

    final assignedIds = _userIdsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final newStation = PumpStation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      totalPumps: int.tryParse(_totalPumpsController.text.trim()) ?? 1,
      status: _selectedStatus,
      assignedUserIds: assignedIds,
      categories: categories.isEmpty ? [AppConstants.catFuelPump] : categories,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    // Add to state
    context.read<PumpProvider>().addStation(newStation);

    // Open Success Screen (Screen 4)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PumpAddedSuccessScreen(station: newStation),
      ),
    );
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
          AppConstants.addNewPump,
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
              // Section Header
              const Text(
                AppConstants.pumpInformation,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),

              // Pump/Station Name
              _buildFieldLabel('Pump/Station Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter pump name' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(hint: 'Enter pump name'),
              ),
              const SizedBox(height: 16),

              // Location
              _buildFieldLabel('Location'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter location' : null,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Enter location',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Total Pumps
              _buildFieldLabel('Total Pumps'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _totalPumpsController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter total pumps';
                  if (int.tryParse(val.trim()) == null) return 'Enter a valid number';
                  return null;
                },
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Enter total pumps',
                  prefixIcon: Icons.local_gas_station_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              _buildFieldLabel('Status'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PumpStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    items: const [
                      DropdownMenuItem(
                        value: PumpStatus.active,
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.figmaEmerald),
                            SizedBox(width: 8),
                            Text('Active', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PumpStatus.inactive,
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 16, color: AppColors.logoutRed),
                            SizedBox(width: 8),
                            Text('Inactive', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assign User IDs
              _buildFieldLabel('Assign User IDs'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _userIdsController,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Enter user IDs (comma separated)\ne.g. 7890, 7891, 7892',
                ),
              ),
              const SizedBox(height: 18),

              // Image Source / Categories
              _buildFieldLabel('Image Source / Categories'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildCheckboxItem('Fuel Pump', _catFuelPump, (val) => setState(() => _catFuelPump = val ?? false)),
                  _buildCheckboxItem('Vehicle', _catVehicle, (val) => setState(() => _catVehicle = val ?? false)),
                  _buildCheckboxItem('Meter', _catMeter, (val) => setState(() => _catMeter = val ?? false)),
                  _buildCheckboxItem('Other', _catOther, (val) => setState(() => _catOther = val ?? false)),
                ],
              ),
              const SizedBox(height: 18),

              // Notes (Optional)
              _buildFieldLabel('Notes (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration(hint: 'Enter any additional notes...'),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    AppConstants.addNewPump,
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
              const SizedBox(height: 20),
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

  Widget _buildCheckboxItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.figmaEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
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
