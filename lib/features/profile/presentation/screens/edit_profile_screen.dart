import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../../widgets/premium_button.dart';

/// NOTE: The backend's User model only stores: email, full_name, university_id,
/// phone_number. There is no course/department/year_of_study on the user yet —
/// those would belong to a separate Student profile that hasn't been built.
/// This screen only edits what the backend can actually persist.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName);
    _phoneController = TextEditingController(text: user?.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AuthTextField(
              controller: _nameController,
              hintText: 'Full Name',
              icon: Iconsax.user,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              icon: Iconsax.call,
            ),
            const SizedBox(height: 16),
            // Admission number is set at registration and is read-only here.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.hashtag, color: AppTheme.getTextSecondary(context)),
                  const SizedBox(width: 12),
                  Text(
                    user?.universityId?.isNotEmpty == true
                        ? user!.universityId!
                        : 'No admission number on file',
                    style: TextStyle(color: AppTheme.getTextSecondary(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              PremiumButton(
                text: 'Save Changes',
                onPressed: () async {
                  await ref.read(authProvider.notifier).updateProfile(
                        fullName: _nameController.text,
                        phoneNumber: _phoneController.text,
                      );
                  if (mounted && ref.read(authProvider).error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                    context.pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
