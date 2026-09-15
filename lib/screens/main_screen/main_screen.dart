import 'package:flutter/material.dart';

import '../../widgets/shared_widgets/bottom_nav_widget.dart';
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

  static const List<Widget> _tabs = [
    DashboardScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
