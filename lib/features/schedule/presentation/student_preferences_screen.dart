import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_button.dart';

/// Allows students to configure or update their multi-tier timetable anchors:
/// Course, Combination/Specialization, Year of Study, Semester, and Group/Stream (e.g., GR K, Group 3).
class StudentPreferencesScreen extends ConsumerStatefulWidget {
  const StudentPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentPreferencesScreen> createState() => _StudentPreferencesScreenState();
}

class _StudentPreferencesScreenState extends ConsumerState<StudentPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers & Selections
  final _courseController = TextEditingController(text: 'Bachelor of Education (Science)');
  final _combinationController = TextEditingController(text: 'Mathematics / Chemistry');
  final _groupController = TextEditingController(text: 'GR K');
  
  int _selectedYear = 1;
  int _selectedSemester = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _courseController.dispose();
    _combinationController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Call your profile update notifier or repository method here
      // Example:
      // await ref.read(authNotifierProvider.notifier).updateProfile(
      //   course: _courseController.text.trim(),
      //   combination: _combinationController.text.trim(),
      //   yearOfStudy: _selectedYear,
      //   semester: _selectedSemester,
      //   timetableGroup: _groupController.text.trim(),
      // );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable stream preferences updated successfully!')),
      );
      context.pop(); // Return to sync or home screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update preferences: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Timetable Stream Setup',
          style: TextStyle(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.info_circle, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select your precise course, subject combination, and group/stream '
                        '(e.g., GR K or Group 3) to ensure common and split units match your exact schedule.',
                        style: TextStyle(
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              // Course Field
              Text(
                'Course / Program',
                style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _courseController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bachelor of Education (Science)',
                  prefixIcon: const Icon(Iconsax.book),
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Combination / Specialization Field
              Text(
                'Subject Combination / Option',
                style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _combinationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Mathematics / Chemistry',
                  prefixIcon: const Icon(Iconsax.shapes),
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Year and Semester Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year of Study',
                          style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          dropdownColor: AppTheme.getSurface(context),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.getSurface(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [1, 2, 3, 4, 5].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                          onChanged: (val) => setState(() => _selectedYear = val ?? 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester',
                          style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedSemester,
                          dropdownColor: AppTheme.getSurface(context),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.getSurface(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: [1, 2].map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val ?? 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Group / Stream Field
              Text(
                'Timetable Group / Stream Tag',
                style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupController,
                decoration: InputDecoration(
                  hintText: 'e.g. GR K, Group 3, GR F',
                  prefixIcon: const Icon(Iconsax.status),
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PremiumButton(
                  text: 'Save & Continue to Sync',
                  onPressed: _savePreferences,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
