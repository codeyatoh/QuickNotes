import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, text }

class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;
  final bool enabled;
  final ButtonType type;

  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.fullWidth = false,
    this.enabled = true,
    this.type = ButtonType.button,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      padding: MaterialStateProperty.all<EdgeInsets>(
        variant == ButtonVariant.text
            ? const EdgeInsets.symmetric(vertical: 8, horizontal: 4)
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      elevation: MaterialStateProperty.all<double>(
        variant == ButtonVariant.primary ? 4 : 2,
      ),
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (states) {
          if (!enabled) {
            return Colors.grey.withOpacity(0.5);
          }
          if (states.contains(MaterialState.pressed)) {
            return _getPressedColor();
          }
          if (states.contains(MaterialState.hovered)) {
            return _getHoverColor();
          }
          return _getBackgroundColor();
        },
      ),
      foregroundColor: MaterialStateProperty.all<Color>(
        variant == ButtonVariant.text
            ? const Color(0xFF6F6F6F)
            : variant == ButtonVariant.secondary
                ? const Color(0xFF1E1E1E)
                : Colors.white,
      ),
      overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
    );

    Widget button = ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: baseStyle,
      child: child,
    );

    if (variant == ButtonVariant.text) {
      button = TextButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) {
              if (!enabled) {
                return Colors.grey.withOpacity(0.5);
              }
              if (states.contains(MaterialState.pressed) ||
                  states.contains(MaterialState.hovered)) {
                return const Color(0xFF1E1E1E);
              }
              return const Color(0xFF6F6F6F);
            },
          ),
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
          textStyle: MaterialStateProperty.all<TextStyle>(
            const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        child: child,
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return const Color(0xFF1E1E1E).withOpacity(0.9);
      case ButtonVariant.secondary:
        return Colors.white.withOpacity(0.6);
      case ButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getHoverColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return const Color(0xFF2D2D2D);
      case ButtonVariant.secondary:
        return Colors.white.withOpacity(0.8);
      case ButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getPressedColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return const Color(0xFF1E1E1E);
      case ButtonVariant.secondary:
        return Colors.white.withOpacity(0.7);
      case ButtonVariant.text:
        return Colors.transparent;
    }
  }
}

enum ButtonType { button, submit, reset }

