import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../widgets/premium_button.dart';

class StudentPreferencesScreen extends ConsumerStatefulWidget {
  const StudentPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentPreferencesScreen> createState() => _StudentPreferencesScreenState();
}

class _StudentPreferencesScreenState extends ConsumerState<StudentPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingMetadata = true;
  bool _isSaving = false;

  // Dropdown options loaded from API
  List<Map<String, dynamic>> _courses = [];
  List<int> _years = [1, 2, 3, 4];
  List<String> _groups = ['MAIN'];

  // Selected values
  String? _selectedCourseId;
  String? _selectedCourseName;
  int _selectedYear = 1;
  int _selectedSemester = 1;
  String _selectedGroup = 'MAIN';
  final _combinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  // Updated to accept filters so selections cascade properly
  Future<void> _fetchMetadata({String? programId, int? yearOfStudy}) async {
    try {
      final dio = apiClient.dio;
      final response = await dio.get(
        'timetable/metadata/',
        queryParameters: {
          if (programId != null) 'program_id': programId,
          if (yearOfStudy != null) 'year_of_study': yearOfStudy,
        },
      );
      
      if (mounted) {
        setState(() {
          _selectedSemester = response.data['semester'] ?? 1;
          _courses = List<Map<String, dynamic>>.from(response.data['courses'] ?? []);
          
          if (_courses.isNotEmpty && _selectedCourseId == null) {
            _selectedCourseId = _courses[0]['id'].toString();
            _selectedCourseName = _courses[0]['name'];
          }

          _years = List<int>.from(response.data['years'] ?? [1, 2, 3, 4]);
          if (_years.isNotEmpty && !_years.contains(_selectedYear)) {
            _selectedYear = _years[0];
          }
          
          _groups = List<String>.from(response.data['groups'] ?? ['MAIN']);
          if (_groups.isNotEmpty && !_groups.contains(_selectedGroup)) {
            _selectedGroup = _groups[0];
          }
          
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load timetable metadata: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _combinationController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = apiClient.dio;
      await dio.patch('accounts/profile/', data: {
        'course': _selectedCourseName,
        'department': 'General',
        'year_of_study': _selectedYear,
        'combination': _combinationController.text.trim(),
        'timetable_group': _selectedGroup,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream preferences updated! Proceeding to portal sync...')),
      );
      context.pushReplacement('/portal-sync');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Timetable Stream Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingMetadata
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Dropdown
                    const Text('Course / Program from Timetable', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      dropdownColor: AppTheme.getSurface(context),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.getSurface(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _courses.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['name'], overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourseId = val;
                          _selectedCourseName = _courses.firstWhere((c) => c['id'].toString() == val)['name'];
                        });
                        // Trigger re-fetch scoped to the selected course and current year
                        _fetchMetadata(programId: val, yearOfStudy: _selectedYear);
                      },
                      validator: (val) => val == null ? 'Please select a course' : null,
                    ),
                    const SizedBox(height: 20),

                    // Subject Combination / Option
                    const Text('Subject Combination / Option (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _combinationController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Math / Chem',
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
                              const Text('Year of Study', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedYear,
                                dropdownColor: AppTheme.getSurface(context),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppTheme.getSurface(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                items: _years.map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedYear = val ?? 1);
                                  // Trigger re-fetch scoped to current course and selected year
                                  _fetchMetadata(programId: _selectedCourseId, yearOfStudy: _selectedYear);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Semester', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Semester $_selectedSemester (Active)', style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Timetable Group / Stream Dropdown
                    const Text('Timetable Group / Stream', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGroup,
                      dropdownColor: AppTheme.getSurface(context),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.getSurface(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGroup = val ?? 'MAIN'),
                    ),
                    const SizedBox(height: 36),

                    // Submit Button
                    if (_isSaving)
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
