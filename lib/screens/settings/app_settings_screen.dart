import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _language = 'English';
  String _theme = 'Light';
  String _autoLogout = 'Never';
  String _cacheSize = '12.5 MB';

  void _clearCache() {
    setState(() => _cacheSize = '0.0 MB');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully!'),
        backgroundColor: AppColors.figmaEmerald,
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
          'App Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          // Language
          _buildSettingsTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: _language,
            onTap: () {
              // Dialog or toggle
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select Language'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _language = 'English');
                        Navigator.pop(ctx);
                      },
                      child: const Text('English'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _language = 'Urdu');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Urdu (اردو)'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDivider(),

          // Theme
          _buildSettingsTile(
            icon: Icons.brightness_medium_outlined,
            title: 'Theme',
            subtitle: _theme,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Select Theme'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _theme = 'Light');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Light'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _theme = 'Dark');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Dark'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDivider(),

          // Auto Logout
          _buildSettingsTile(
            icon: Icons.timer_outlined,
            title: 'Auto Logout',
            subtitle: _autoLogout,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Auto Logout Duration'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _autoLogout = 'Never');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Never'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _autoLogout = '15 minutes');
                        Navigator.pop(ctx);
                      },
                      child: const Text('15 minutes'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() => _autoLogout = '30 minutes');
                        Navigator.pop(ctx);
                      },
                      child: const Text('30 minutes'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDivider(),

          // Clear Cache
          _buildSettingsTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Cache',
            subtitle: _cacheSize,
            onTap: _clearCache,
          ),
          _buildDivider(),

          // App Version
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: 'v1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.headerGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.figmaEmerald, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 74, right: 20),
      child: Divider(height: 1, color: AppColors.borderLight),
    );
  }
}
