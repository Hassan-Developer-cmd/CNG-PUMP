import 'package:flutter/material.dart';

import '../../widgets/shared_widgets/bottom_nav_widget.dart';
import '../../widgets/shared_widgets/exit_confirmation_dialog.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';

/// Root screen after login. Hosts the shared [BottomNavWidget] and swaps
/// between the Dashboard ("Capture") and History tabs, keeping
/// each tab's state alive via an IndexedStack.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isExitDialogOpen = false;

  static const List<Widget> _tabs = [
    DashboardScreen(),
    HistoryScreen(),
  ];

  Future<void> _handlePopScope(bool didPop) async {
    if (didPop) return;

    // If on History (or other secondary tab), navigate back to Dashboard.
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // User is on Dashboard (the root screen). Show exit confirmation dialog.
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
