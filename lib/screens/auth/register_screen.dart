import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ToastUtil.showError(
        context,
        title: 'Password Mismatch',
        message: 'The passwords you entered do not match. Please try again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // User is automatically logged in after registration
        // Navigate to onboarding screen for new accounts
        
        // Get root navigator context before navigating
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        final rootContext = rootNavigator.context;
        
        // Navigate to onboarding screen immediately
        Navigator.of(context).pushReplacementNamed('/onboarding');
        
        // Show success message on onboarding screen after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            ToastUtil.showSuccess(
              rootContext,
              title: 'Account Created!',
              message: 'Welcome! Let\'s get started with QuickNotes.',
              buttonText: 'Continue',
              duration: const Duration(seconds: 3),
            );
          } catch (e) {
            // Silently fail if context is no longer valid
          }
        });
      } else {
        ToastUtil.showError(
          context,
          title: 'Registration Failed',
          message: authProvider.lastError ?? 'Unable to create your account. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // iPhone SE is ~667px
    final headerHeight = isSmallScreen ? screenHeight * 0.32 : screenHeight * 0.4;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dark header section - smaller on small screens
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  // Back button on the left
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  // "Sign up" title next to arrow
                  Text(
                    'Sign up',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // White form section with rounded top corners, shadow, and overlap
          Positioned(
            top: headerHeight - 22, // Overlap by ~22px
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: isSmallScreen ? 12 : 20,
                      bottom: MediaQuery.of(context).padding.bottom + (isSmallScreen ? 4 : 12),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Full Name field
                          Text(
                            'Full Name',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _fullNameController,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outlined,
                                  color: const Color(0xFF2D2D2D),
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Email field
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: const Color(0xFF2D2D2D),
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Password field
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outlined,
                                  color: const Color(0xFF2D2D2D),
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF2D2D2D),
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          // Confirm Password field
                          Text(
                            'Confirm Password',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: !_showConfirmPassword,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outlined,
                                  color: const Color(0xFF2D2D2D),
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF2D2D2D),
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showConfirmPassword = !_showConfirmPassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 24),
                          // Register button - centered, matching Sign in button style
                          Center(
                            child: SizedBox(
                              width: 200,
                              height: isSmallScreen ? 46 : 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _handleRegister,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                        'Register',
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 15 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}