import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

/// Landing page for the password reset link sent by email
/// (`/reset-password?token=…`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum _ResetStage { form, success, invalidLink }

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _minLength = 8;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late _ResetStage _stage =
      widget.token.trim().isEmpty ? _ResetStage.invalidLink : _ResetStage.form;
  bool _isSubmitting = false;
  bool _attemptedSubmit = false;
  String? _error;

  String get _password => _passwordController.text;
  String get _confirmation => _confirmController.text;

  bool get _hasLength => _password.length >= _minLength;
  bool get _hasLetter => RegExp(r'[A-Za-z]').hasMatch(_password);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password);
  bool get _matches => _confirmation.isNotEmpty && _password == _confirmation;
  bool get _isValid => _hasLength && _hasLetter && _hasNumber && _matches;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _attemptedSubmit = true;
      _error = null;
    });
    if (!_isValid) {
      setState(() => _error = _password.isEmpty
          ? 'Enter a new password.'
          : !_matches
              ? 'Passwords do not match.'
              : 'Your password does not meet the requirements below.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            token: widget.token.trim(),
            newPassword: _password,
            confirmPassword: _confirmation,
          );
      TextInput.finishAutofillContext();
      if (mounted) setState(() => _stage = _ResetStage.success);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      final lower = message.toLowerCase();
      if (lower.contains('invalid') || lower.contains('expired') || lower.contains('token')) {
        setState(() => _stage = _ResetStage.invalidLink);
      } else {
        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_stage) {
                  _ResetStage.form => _buildForm(context),
                  _ResetStage.success => _buildSuccess(context),
                  _ResetStage.invalidLink => _buildInvalidLink(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return AutofillGroup(
      key: const ValueKey('form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderIcon(icon: Iconsax.key, color: AppTheme.primary)
              .animate().fadeIn().scale(),
          const SizedBox(height: 32),
          Text(
            'Choose a new password',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ).animate().fadeIn(delay: 100.ms).moveY(begin: 10),
          const SizedBox(height: 8),
          Text(
            'Your new password must be different from ones you use elsewhere. '
            'This link expires 15 minutes after it was sent.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 150.ms).moveY(begin: 10),
          const SizedBox(height: 32),
          AuthTextField(
            hintText: 'New password',
            icon: Iconsax.lock,
            isPassword: true,
            controller: _passwordController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() => _error = null),
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
          const SizedBox(height: 16),
          AuthTextField(
            hintText: 'Confirm new password',
            icon: Iconsax.lock_1,
            isPassword: true,
            controller: _confirmController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ).animate().fadeIn(delay: 250.ms).moveY(begin: 10),
          const SizedBox(height: 20),
          _RequirementList(
            showFailures: _attemptedSubmit,
            requirements: [
              ('At least $_minLength characters', _hasLength),
              ('Contains a letter', _hasLetter),
              ('Contains a number', _hasNumber),
              ('Passwords match', _matches),
            ],
          ).animate().fadeIn(delay: 300.ms),
          if (_error != null) ...[
            const SizedBox(height: 20),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 28),
          PremiumButton(
            text: 'Update password',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ).animate().fadeIn(delay: 350.ms).scale(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isSubmitting ? null : () => context.go('/'),
            child: Text(
              'Back to sign in',
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Iconsax.tick_circle, color: AppTheme.success)
            .animate().fadeIn().scale(),
        const SizedBox(height: 32),
        Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been changed. Sign in with your new password to continue.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        PremiumButton(
          text: 'Continue to sign in',
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  Widget _buildInvalidLink(BuildContext context) {
    return Column(
      key: const ValueKey('invalid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Iconsax.link_21, color: AppTheme.error)
            .animate().fadeIn().scale(),
        const SizedBox(height: 32),
        Text(
          'Link expired or invalid',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Reset links work once and expire after 15 minutes. '
          'Request a new link and use the most recent email we send you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        PremiumButton(
          text: 'Request a new link',
          onPressed: () => context.go('/forgot-password'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/'),
          child: Text(
            'Back to sign in',
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _HeaderIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 40, color: color),
      ),
    );
  }
}

class _RequirementList extends StatelessWidget {
  final List<(String, bool)> requirements;
  final bool showFailures;

  const _RequirementList({required this.requirements, required this.showFailures});

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getTextSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, met) in requirements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  met ? Iconsax.tick_circle5 : Iconsax.record,
                  size: 16,
                  color: met
                      ? AppTheme.success
                      : showFailures
                          ? AppTheme.error
                          : muted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: met
                        ? AppTheme.getTextPrimary(context)
                        : showFailures
                            ? AppTheme.error
                            : muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.warning_2, size: 18, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.error, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
