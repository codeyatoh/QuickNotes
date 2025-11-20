import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/toast_util.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetCode(
      _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Navigate to verify code screen
        Navigator.of(context).pushNamed(
          '/verify-code',
          arguments: _emailController.text.trim(),
        );

        ToastUtil.showSuccess(
          context,
          title: 'Code Sent!',
          message: 'Check your email for the verification code.',
          duration: const Duration(seconds: 3),
        );
      } else {
        ToastUtil.showError(
          context,
          title: 'Failed to Send Code',
          message: authProvider.lastError ?? 'Unable to send verification code. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.4;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dark header section - 40% of viewport
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
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // "Quick" and "notes" text on the left
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quick',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'notes',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Circular logo on the right
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.logoAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            AppConstants.logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.note,
                                  size: 45,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          );
                        },
                      ),
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
                  final isSmallScreen = constraints.maxHeight < 600;
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: isSmallScreen ? 24 : 32,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              color: AppColors.textPrimary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            'Forgot Password?',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 12),
                          // Description
                          Text(
                            'Enter your email address and we\'ll send you a verification code to reset your password.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 28 : 36),
                          // Email field
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF2D2D2D),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 32 : 40),
                          // Send code button
                          Center(
                            child: SizedBox(
                              width: 200,
                              height: isSmallScreen ? 48 : 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? Colors.grey.shade400
                                      : const Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _handleSendCode,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Send Code',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
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
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          // Back to login
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Back to Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                          ),
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
