import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/toast_util.dart';
import '../../theme/app_colors.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  Future<void> _handleVerifyCode() async {
    if (_code.length != 6) {
      ToastUtil.showError(
        context,
        title: 'Invalid Code',
        message: 'Please enter the complete 6-digit code.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyPasswordResetCode(
      widget.email,
      _code,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Navigate to reset password screen
        Navigator.of(context).pushReplacementNamed(
          '/reset-password',
          arguments: {
            'email': widget.email,
            'code': _code,
          },
        );

        ToastUtil.showSuccess(
          context,
          title: 'Code Verified!',
          message: 'You can now reset your password.',
          duration: const Duration(seconds: 2),
        );
      } else {
        ToastUtil.showError(
          context,
          title: 'Invalid Code',
          message: authProvider.lastError ?? 'The code you entered is incorrect. Please try again.',
        );
      }
    }
  }

  Future<void> _handleResendCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetCode(widget.email);

    if (mounted) {
      if (success) {
        ToastUtil.showSuccess(
          context,
          title: 'Code Resent!',
          message: 'A new verification code has been sent to your email.',
          duration: const Duration(seconds: 3),
        );
      } else {
        ToastUtil.showError(
          context,
          title: 'Failed to Resend',
          message: authProvider.lastError ?? 'Unable to resend code. Please try again.',
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
                          'Verify Code',
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
                          'We\'ve sent a 6-digit verification code to',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D2D2D),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 32 : 40),
                        // 6-digit code input
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 48,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _codeControllers[index].text.isNotEmpty
                                        ? const Color(0xFF2D2D2D)
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _codeControllers[index],
                                  focusNode: _focusNodes[index],
                                  enabled: !_isLoading,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                    if (value.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    } else if (value.isNotEmpty && index == 5) {
                                      // Automatically verify when last digit is entered
                                      _focusNodes[index].unfocus();
                                      _handleVerifyCode();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: isSmallScreen ? 32 : 40),
                        // Verify button
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: isSmallScreen ? 48 : 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isLoading || _code.length != 6
                                    ? Colors.grey.shade400
                                    : const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading || _code.length != 6
                                      ? null
                                      : _handleVerifyCode,
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
                                            'Verify Code',
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
                        // Resend code
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Didn\'t receive code? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _handleResendCode,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Resend',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
