import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Minimalist cute popup feedback system
class FeedbackPopup {
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    String buttonText = 'Done',
    Duration autoDismissDuration = const Duration(seconds: 3),
    VoidCallback? onButtonPressed,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => _FeedbackPopupWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        buttonText: buttonText,
        autoDismissDuration: autoDismissDuration,
        onButtonPressed: onButtonPressed,
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String subtitle,
    String buttonText = 'Done',
    Duration autoDismissDuration = const Duration(seconds: 2),
    VoidCallback? onButtonPressed,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.check_circle_rounded,
      accentColor: AppColors.tagGreen,
      buttonText: buttonText,
      autoDismissDuration: autoDismissDuration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String subtitle,
    String buttonText = 'OK',
    Duration autoDismissDuration = const Duration(seconds: 3),
    VoidCallback? onButtonPressed,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.error_rounded,
      accentColor: AppColors.tagRed,
      buttonText: buttonText,
      autoDismissDuration: autoDismissDuration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String subtitle,
    String buttonText = 'OK',
    Duration autoDismissDuration = const Duration(seconds: 3),
    VoidCallback? onButtonPressed,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.warning_rounded,
      accentColor: AppColors.tagYellow,
      buttonText: buttonText,
      autoDismissDuration: autoDismissDuration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String subtitle,
    String buttonText = 'OK',
    Duration autoDismissDuration = const Duration(seconds: 2),
    VoidCallback? onButtonPressed,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.info_rounded,
      accentColor: AppColors.tagBlue,
      buttonText: buttonText,
      autoDismissDuration: autoDismissDuration,
      onButtonPressed: onButtonPressed,
    );
  }
}

class _FeedbackPopupWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String buttonText;
  final Duration autoDismissDuration;
  final VoidCallback? onButtonPressed;

  const _FeedbackPopupWidget({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.buttonText,
    required this.autoDismissDuration,
    this.onButtonPressed,
  });

  @override
  State<_FeedbackPopupWidget> createState() => _FeedbackPopupWidgetState();
}

class _FeedbackPopupWidgetState extends State<_FeedbackPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.autoDismissDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    
    _controller.reverse().then((_) {
      if (!mounted) return;
      
      // Safely pop the dialog
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
      
      // Call callback after a small delay to ensure dialog is closed
      if (widget.onButtonPressed != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            widget.onButtonPressed?.call();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppColors.textTertiary;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _dismiss();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Blurred background overlay with gradient
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Popup card
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cute icon with soft background
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accentColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Cute button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _dismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

