import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/theme/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// "Change Password" on the profile screens. SMARTTT has no in-app change, so after a
/// confirmation this emails the same reset link as "Forgot Password?" on sign-in.
Future<void> sendChangePasswordLink(BuildContext context, WidgetRef ref, String email) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('Change Password')),
      content: Text('${ctx.tr('We will email a link to choose a new password to')} $email.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(ctx.tr('Cancel'))),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(ctx.tr('Send link'))),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final sent = context.tr('Check your inbox for the link.');
  try {
    await ref.read(authRepositoryProvider).forgotPassword(email);
    messenger.showSnackBar(SnackBar(content: Text(sent)));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error, fallbackMessage: 'Could not send the link. Please try again.'))));
  }
}
