import 'package:flutter/material.dart';
import '../config/theme.dart';

enum CustomButtonStyle {
  primary,
  secondary,
  danger,
  ghost,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonStyle style;
  final IconData? icon;
  final bool fullWidth;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style = CustomButtonStyle.primary,
    this.icon,
    this.fullWidth = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? 48.0;
    
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    
    switch (style) {
      case CustomButtonStyle.primary:
        backgroundColor = AppTheme.primaryColor;
        foregroundColor = Colors.white;
        borderColor = AppTheme.primaryColor;
        break;
      case CustomButtonStyle.secondary:
        backgroundColor = AppTheme.backgroundColor;
        foregroundColor = AppTheme.textPrimary;
        borderColor = AppTheme.borderColor;
        break;
      case CustomButtonStyle.danger:
        backgroundColor = AppTheme.errorColor;
        foregroundColor = Colors.white;
        borderColor = AppTheme.errorColor;
        break;
      case CustomButtonStyle.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        break;
    }

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
        ),
        child: child,
      ),
    );
  }
}