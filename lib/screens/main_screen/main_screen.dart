import 'package:flutter/material.dart';
import '../../widgets/shared_widgets/bottom_nav_widget.dart';
import '../../widgets/shared_widgets/exit_confirmation_dialog.dart';
import '../history/history_screen.dart';
import '../pumps/pumps_list_screen.dart';
import '../settings/settings_screen.dart';

/// Root navigation shell for the Admin flow hosting the 3 tabs:
/// 1. Pumps (PumpsListScreen)
/// 2. History (HistoryScreen)
/// 3. Settings (SettingsScreen)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isExitDialogOpen = false;

  static const List<Widget> _tabs = [
    PumpsListScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  Future<void> _handlePopScope(bool didPop) async {
    if (didPop) return;

    // If on a secondary tab, navigate back to Pumps tab (index 0).
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // User is on Pumps tab (root). Show exit confirmation dialog.
    if (_isExitDialogOpen) return;

    _isExitDialogOpen = true;
    try {
      await ExitConfirmationDialog.show(context);
    } finally {
      _isExitDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePopScope(didPop),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: BottomNavWidget(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
