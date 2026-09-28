import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: (color ?? AppTheme.primary).withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
