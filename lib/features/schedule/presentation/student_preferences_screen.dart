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
  // The distinct sub-streams for the selected course+year (e.g. the "1"/"2"
  // in "BED.MATH/CHEM Y3S1(1)"/"(2)") - see TimetableSlot.stream on the
  // backend. Empty means this course+year isn't split, so there's nothing
  // to disambiguate and the picker should stay hidden.
  List<String> _streams = [];

  // Selected values
  // NOTE: _selectedCourseId is a *canonical group key* (see
  // apps.programs.utils.canonical_program_key on the backend), not a raw
  // Program row id — the same-looking program can be split across several
  // duplicated Program rows (e.g. one covering years 1-2, another 3-4), and
  // the backend groups them so this dropdown shows one entry with the full
  // union of years instead of the program appearing twice with partial years.
  String? _selectedCourseId;
  String? _selectedCourseName;
  int _selectedYear = 1;
  int _selectedSemester = 1;
  // Null when the course+year has no streams to pick between - saved as an
  // empty timetable_group so the backend schedule query treats every slot
  // for that unit as the student's own, instead of filtering by a stream
  // value ("MAIN") that no real TimetableSlot ever carries.
  String? _selectedStream;
  // The concrete Program row id to actually save, resolved by the backend
  // for the current course+year combination. Null until the backend has had
  // a chance to resolve it (which happens as soon as a course is selected).
  String? _resolvedProgramId;
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
          
          _streams = List<String>.from(response.data['streams'] ?? []);
          if (_streams.isEmpty) {
            _selectedStream = null;
          } else if (_selectedStream == null || !_streams.contains(_selectedStream)) {
            _selectedStream = _streams[0];
          }

          _resolvedProgramId = response.data['resolved_program_id'] as String?;
          
          _isLoadingMetadata = false;
        });

        // First load: we now have a default course+year selected, but the
        // call above didn't scope by them, so resolved_program_id wasn't
        // returned yet. Re-fetch scoped to the defaults to resolve it.
        if (programId == null && yearOfStudy == null && _selectedCourseId != null) {
          await _fetchMetadata(programId: _selectedCourseId, yearOfStudy: _selectedYear);
        }
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
      // Change 'accounts/profile/' to 'auth/profile/'
      await dio.patch('auth/profile/', data: {
        // Prefer linking the real, already-parsed Program row the backend
        // resolved for this course+year — this is what the master timetable
        // (and therefore the student's personalised schedule) is actually
        // keyed on. 'course'/'department' are sent only as a fallback for
        // the rare case resolution failed (e.g. a term with no slots yet);
        // saving those directly would otherwise create a brand-new,
        // disconnected Program record under a generic department instead of
        // reusing the one the timetable upload already created.
        if (_resolvedProgramId != null) 'program_id': _resolvedProgramId,
        'course': _selectedCourseName,
        'department': 'General',
        'year_of_study': _selectedYear,
        'combination': _combinationController.text.trim(),
        'timetable_group': _selectedStream ?? '',
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
                    // Stream picker — only shown when this course+year is
                    // actually split into multiple parallel classes on the
                    // master timetable (e.g. BED.MATH/CHEM Y3S1 has streams
                    // "1" and "2"). Most courses have just one class, so
                    // there's nothing to disambiguate and the picker is
                    // skipped entirely rather than showing a single option.
                    if (_streams.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Class / Stream', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const Text(
                        'Your course has more than one class this year — pick yours from the timetable.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStream,
                        dropdownColor: AppTheme.getSurface(context),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.getSurface(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _streams
                            .map((s) => DropdownMenuItem(value: s, child: Text('Stream $s')))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedStream = val),
                        validator: (val) => val == null ? 'Please select your class/stream' : null,
                      ),
                    ],
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
