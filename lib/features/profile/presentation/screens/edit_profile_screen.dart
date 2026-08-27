import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../../widgets/premium_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _admissionController;
  late TextEditingController _courseController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _admissionController = TextEditingController(text: user?.universityId);
    _courseController = TextEditingController(text: user?.course);
    _departmentController = TextEditingController(text: user?.department);
    _yearController = TextEditingController(text: user?.yearOfStudy?.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _admissionController.dispose();
    _courseController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
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
            AuthTextField(
              controller: _admissionController,
              hintText: 'Admission Number',
              icon: Iconsax.hashtag,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _courseController,
              hintText: 'Course',
              icon: Iconsax.book,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _departmentController,
              hintText: 'Department',
              icon: Iconsax.building,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _yearController,
              hintText: 'Year of Study',
              icon: Iconsax.calendar,
              keyboardType: TextInputType.number,
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
                        admissionNumber: _admissionController.text,
                        course: _courseController.text,
                        department: _departmentController.text,
                        yearOfStudy: int.tryParse(_yearController.text),
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
