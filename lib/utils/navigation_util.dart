import 'package:flutter/material.dart';

/// Utility class for safe navigation operations
class NavigationUtil {
  /// Safely pop the current route, or navigate to home if can't pop
  static void safePopOrNavigate(BuildContext context, String fallbackRoute) {
    if (!context.mounted) return;
    
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else {
      Navigator.of(context).pushReplacementNamed(fallbackRoute);
    }
  }

  /// Safely pop the current route
  static void safePop(BuildContext context) {
    if (!context.mounted) return;
    
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Check if navigation can pop
  static bool canPop(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    return navigator != null && navigator.canPop();
  }
}

