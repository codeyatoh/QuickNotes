import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../utils/toast_util.dart';
import '../../theme/app_colors.dart';
import '../../utils/navigation_util.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationUtil.safePopOrNavigate(context, '/home');
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => NavigationUtil.safePopOrNavigate(context, '/home'),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          const Text(
            'ACCOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.textPrimary),
            title: const Text(
              'Account Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              authProvider.user?.email ?? 'Manage your account',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onTap: () {
              Navigator.of(context).pushNamed('/account-settings');
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          // Preferences section
          const Text(
            'PREFERENCES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: AppColors.textPrimary),
            title: const Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              isDarkMode ? 'Enabled' : 'Disabled',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) async {
                await themeProvider.toggleTheme();
                
                if (context.mounted) {
                  final userSettings = Provider.of<UserSettingsProvider>(context, listen: false);
                  final theme = userSettings.theme;
                  ToastUtil.showSuccess(
                    context,
                    title: 'Theme Updated',
                    message: 'Your theme has been changed to ${theme == 'dark' ? 'Dark Mode' : 'Light Mode'}.',
                  );
                }
              },
            ),
          ),
          const Divider(),
          const SizedBox(height: 24),
          // Data section
          const Text(
            'DATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.cloud, color: AppColors.textPrimary),
            title: const Text(
              'Backup & Restore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Cloud backup options',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download, color: AppColors.textPrimary),
            title: const Text(
              'Export Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Export as PDF or text',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.textPrimary),
            title: const Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'App version, help, feedback',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onTap: () {},
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            subtitle: const Text(
              'Sign out of your account',
              style: TextStyle(
                fontSize: 14,
                color: Colors.redAccent,
                fontWeight: FontWeight.w300,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () async {
              // Get root navigator context before logout
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              final rootContext = rootNavigator.context;
              
              // Navigate immediately for faster UX (don't wait for logout)
              Navigator.of(context).pushReplacementNamed('/login');
              
              // Logout in background
              authProvider.logout();
              
              // Show success message on login screen after navigation
              Future.delayed(const Duration(milliseconds: 300), () {
                try {
                  ToastUtil.showInfo(
                    rootContext,
                    title: 'Logged Out',
                    message: 'You have been successfully logged out.',
                    buttonText: 'OK',
                    duration: const Duration(seconds: 2),
                  );
                } catch (e) {
                  // Silently fail if context is no longer valid
                }
              });
            },
            tileColor: Colors.red.shade50.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
