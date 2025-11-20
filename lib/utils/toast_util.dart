import 'package:flutter/material.dart';
import '../widgets/feedback_popup.dart';

/// Minimalist popup feedback utility
class ToastUtil {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success!',
    String buttonText = 'Done',
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onButtonPressed,
  }) {
    if (!context.mounted) return;
    
    FeedbackPopup.showSuccess(
      context,
      title: title,
      subtitle: message,
      buttonText: buttonText,
      autoDismissDuration: duration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Error',
    String buttonText = 'OK',
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onButtonPressed,
  }) {
    if (!context.mounted) return;
    
    FeedbackPopup.showError(
      context,
      title: title,
      subtitle: message,
      buttonText: buttonText,
      autoDismissDuration: duration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'Info',
    String buttonText = 'OK',
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onButtonPressed,
  }) {
    if (!context.mounted) return;
    
    FeedbackPopup.showInfo(
      context,
      title: title,
      subtitle: message,
      buttonText: buttonText,
      autoDismissDuration: duration,
      onButtonPressed: onButtonPressed,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String title = 'Warning',
    String buttonText = 'OK',
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onButtonPressed,
  }) {
    if (!context.mounted) return;
    
    FeedbackPopup.showWarning(
      context,
      title: title,
      subtitle: message,
      buttonText: buttonText,
      autoDismissDuration: duration,
      onButtonPressed: onButtonPressed,
    );
  }
}

