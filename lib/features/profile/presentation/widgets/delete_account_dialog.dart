import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';

/// Shows the delete-account confirmation flow: a warning dialog, then a
/// password-confirmation step, then calls the delete endpoint. Returns
/// true if the account was actually deleted (so the caller can navigate
/// to /login), false/null otherwise.
Future<bool?> showDeleteAccountDialog(BuildContext context) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _WarningDialog(),
  );
  if (proceed != true) return false;
  if (!context.mounted) return false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _PasswordConfirmDialog(),
  );
}

class _WarningDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Iconsax.danger, color: AppTheme.error, size: 28),
      ),
      title: Text(
        context.tr('Delete Account?'),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold),
      ),
      content: Text(
        context.tr(
          'This deactivates your account and signs you out of every device. '
          'Your academic records are kept, but you will need to contact support '
          'to reactivate. Continue?',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('Cancel'), style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(context.tr('Continue')),
        ),
      ],
    );
  }
}

class _PasswordConfirmDialog extends ConsumerStatefulWidget {
  const _PasswordConfirmDialog();

  @override
  ConsumerState<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends ConsumerState<_PasswordConfirmDialog> {
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = context.tr('Enter your password to continue.'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).deleteAccount(password);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e.toString().startsWith('Exception: ') ? e.toString().substring(11) : e.toString();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.tr('Confirm Your Password'),
        style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('For your security, please enter your password to permanently delete your account.'),
            style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            hintText: context.tr('Password'),
            icon: Iconsax.lock,
            isPassword: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(context.tr('Cancel'), style: TextStyle(color: AppTheme.getTextSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _confirmDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(context.tr('Delete Account')),
        ),
      ],
    );
  }
}
