import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/department_model.dart';

/// Department picker styled to match AuthTextField (same border, radius,
/// padding) so it drops into the register form without looking out of place.
class AuthDropdownField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final List<DepartmentModel> items;
  final DepartmentModel? value;
  final bool isLoading;
  final ValueChanged<DepartmentModel?> onChanged;

  const AuthDropdownField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white70 : AppTheme.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isLoading
          ? SizedBox(
              height: 56,
              child: Row(
                children: [
                  Icon(icon, color: hintColor, size: 20),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Loading departments…', style: TextStyle(color: hintColor)),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButtonFormField<DepartmentModel>(
                value: value,
                isExpanded: true,
                icon: Icon(Iconsax.arrow_down_1, color: hintColor, size: 18),
                dropdownColor: backgroundColor,
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  prefixIcon: Icon(icon, color: hintColor, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
                hint: Text(hintText, style: TextStyle(color: hintColor)),
                items: items
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
    );
  }
}