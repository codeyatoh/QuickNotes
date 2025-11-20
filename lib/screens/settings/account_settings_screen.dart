import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../utils/navigation_util.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _success = null;
    });

    // Validate passwords if user is trying to change password
    if (_newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      if (_currentPasswordController.text.isEmpty) {
        setState(() {
          _error = 'Current password is required to change password';
        });
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _error = 'New passwords do not match';
        });
        return;
      }
      if (_newPasswordController.text.length < 6) {
        setState(() {
          _error = 'New password must be at least 6 characters';
        });
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final updated = await authProvider.updateUser(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _currentPasswordController.text.isEmpty
          ? null
          : _currentPasswordController.text,
      _newPasswordController.text.isEmpty ? null : _newPasswordController.text,
    );

    if (updated && mounted) {
      // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      
      // Show success popup
      ToastUtil.showSuccess(
        context,
        title: 'Profile Updated!',
        message: 'Your account information has been updated successfully in both Authentication and Firestore.',
        buttonText: 'Done',
        duration: const Duration(seconds: 2),
        onButtonPressed: () {
        if (mounted) {
          Navigator.of(context).pop();
          }
        },
      );
      
      // Auto-navigate after delay if user doesn't press button
      Future.delayed(const Duration(milliseconds: 2100), () {
        if (mounted) {
          final navigator = Navigator.maybeOf(context);
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
        }
      });
    } else if (mounted) {
      // Show error popup with specific error message
      final errorMessage = authProvider.lastError ?? 'Failed to update account. Please try again.';
      ToastUtil.showError(
        context,
        title: 'Update Failed',
        message: errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationUtil.safePopOrNavigate(context, '/settings');
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => NavigationUtil.safePopOrNavigate(context, '/settings'),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F0F0),
              Colors.white,
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade100.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                if (_success != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade100.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _success!,
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                const Text(
                  'PROFILE INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Name',
                  placeholder: 'Enter your name',
                  controller: _nameController,
                  required: true,
                  prefixIcon: const Icon(Icons.person, size: 20),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  placeholder: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                  prefixIcon: const Icon(Icons.email, size: 20),
                ),
                const SizedBox(height: 32),
                const Text(
                  'CHANGE PASSWORD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Leave blank if you don\'t want to change your password',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Current Password',
                  placeholder: 'Enter current password',
                  controller: _currentPasswordController,
                  obscureText: !_showCurrentPassword,
                  prefixIcon: const Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password',
                  placeholder: 'Enter new password',
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  prefixIcon: const Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password',
                  placeholder: 'Confirm new password',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  prefixIcon: const Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: _handleSave,
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

