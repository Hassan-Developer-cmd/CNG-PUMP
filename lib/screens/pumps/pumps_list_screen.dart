import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/pump_station_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/pump_provider.dart';
import '../../widgets/pumps/pump_station_card.dart';
import '../../widgets/shared_widgets/async_state_view.dart';
import '../settings/profile_screen.dart';
import '../users/operator_user_screen.dart';
import '../users/users_screen.dart';
import 'add_pump_screen.dart';

class PumpsListScreen extends StatefulWidget {
  const PumpsListScreen({super.key});

  @override
  State<PumpsListScreen> createState() => _PumpsListScreenState();
}

class _PumpsListScreenState extends State<PumpsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PumpProvider>().fetchStations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddPump(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPumpScreen()),
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Navigation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.figmaEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: AppColors.figmaEmerald),
                  ),
                  title: const Text('Users & Operators', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage station operators & supervisors'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UsersScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.figmaEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.figmaEmerald),
                  ),
                  title: const Text('Operator Reading Screen', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Switch to nozzle/meter capture view'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OperatorUserScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.figmaEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.figmaEmerald),
                  ),
                  title: const Text('Admin Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View and edit profile details'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStationDetail(BuildContext context, PumpStation station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: station.isActive
                            ? AppColors.badgeActiveBg
                            : AppColors.badgeInactiveBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        station.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: station.isActive
                              ? AppColors.badgeActiveText
                              : AppColors.badgeInactiveText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(station.location, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.local_gas_station_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${station.totalPumps} Pumps', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                if (station.assignedUserIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Assigned Operators: ${station.assignedUserIds.join(', ')}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
                if (station.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Categories: ${station.categories.join(', ')}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
                if (station.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${station.notes}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.figmaPrimaryBtn,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProfile = context.watch<AdminAuthProvider>().profile;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: AppColors.figmaDarkGreen,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Logo
                  Image.asset(
                    AppConstants.appLogo,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_gas_station_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // App Title & Subtitle
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppConstants.pumpAdminSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Admin Profile Pill
                  GestureDetector(
                    onTap: () => _showAdminMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: AppColors.figmaDarkGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            adminProfile.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<PumpProvider>(
        builder: (context, pumpProvider, _) {
          final stations = pumpProvider.filteredStations;

          return Column(
            children: [
              // Header Row: "Pumps" + "+ Add New Pump"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppConstants.navPumps,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openAddPump(context),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text(
                        AppConstants.addNewPump,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.figmaPrimaryBtn,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: pumpProvider.setSearchQuery,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search pumps...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                pumpProvider.clearSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Stations List
              Expanded(
                child: AsyncStateView(
                  status: pumpProvider.isLoading
                      ? AsyncStatus.loading
                      : pumpProvider.hasError
                          ? AsyncStatus.error
                          : stations.isEmpty
                              ? AsyncStatus.empty
                              : AsyncStatus.loaded,
                  errorMessage: pumpProvider.errorMessage,
                  emptyTitle: 'No Pumps Found',
                  emptySubtitle: _searchController.text.isNotEmpty
                      ? 'Try adjusting your search terms'
                      : 'Tap "+ Add New Pump" to create one',
                  emptyIcon: Icons.local_gas_station_outlined,
                  onRetry: pumpProvider.fetchStations,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      return PumpStationCard(
                        station: station,
                        onTap: () => _showStationDetail(context, station),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
