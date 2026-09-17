import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../domain/models/lecturer_dashboard_model.dart';
import '../../data/lecturer_repository.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/lecturer_colors.dart';

class LecturerNotificationTab extends ConsumerStatefulWidget {
  const LecturerNotificationTab({super.key});

  @override
  ConsumerState<LecturerNotificationTab> createState() => _LecturerNotificationTabState();
}

class _LecturerNotificationTabState extends ConsumerState<LecturerNotificationTab> {
  String? selectedUnitId;
  String notifType = 'general'; // 'general', 'timetable_change', 'venue_change', 'reschedule'

  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final reasonController = TextEditingController();

  // Reschedule specific states
  String? selectedSlotId;
  List<Map<String, dynamic>> availableSlotsForUnit = [];
  bool isLoadingSlots = false;

  String selectedDay = 'mon';
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

  // Venue-change specific states
  String? selectedVenueId;
  List<RoomModel> rooms = [];
  bool isLoadingRooms = false;
  final expectedStudentsController = TextEditingController();

  bool isSending = false;
  String? alertMessage;
  bool isSuccess = false;

  // Backend TimetableSlot.WeekDay only defines Mon–Sat.
  final List<String> days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    reasonController.dispose();
    expectedStudentsController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    setState(() => isLoadingRooms = true);
    try {
      final result = await ref.read(lecturerRepositoryProvider).fetchRooms();
      setState(() {
        rooms = result;
        isLoadingRooms = false;
      });
    } catch (e) {
      setState(() => isLoadingRooms = false);
    }
  }

  Future<void> _fetchSlotsForUnit(String unitId) async {
    setState(() {
      isLoadingSlots = true;
      selectedSlotId = null;
      availableSlotsForUnit = [];
    });

    try {
      // Server-side filtered by unit, so this only ever returns slots for
      // the selected unit rather than relying on scanning a fixed page of
      // the full (thousands-of-rows) slot list client-side.
      final response = await apiClient.dio.get(
        'timetable/slots/',
        queryParameters: {'unit': unitId, 'page_size': 200},
      );

      final dynamic rawData = response.data;
      final List<Map<String, dynamic>> slots = rawData is List
          ? List<Map<String, dynamic>>.from(rawData)
          : List<Map<String, dynamic>>.from(rawData['results'] ?? []);

      setState(() {
        availableSlotsForUnit = slots;
        isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSlots = false;
        availableSlotsForUnit = [];
      });
    }
  }

  TextStyle _labelStyle(bool isDarkMode) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.grey[400] : Colors.grey,
      );

  TextStyle _fieldTextStyle(bool isDarkMode) => TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      );

  InputDecoration _fieldDecoration(bool isDarkMode, {String? hintText}) {
    final borderColor = isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: LecturerColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(lecturerDashboardProvider).dashboard;
    final units = dashboard?.units ?? [];
    final isReschedule = notifType == 'reschedule';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Lecturer Broadcast & Reschedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alertMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? (isDarkMode ? Colors.green.withValues(alpha: 0.15) : Colors.green[50])
                        : (isDarkMode ? Colors.red.withValues(alpha: 0.15) : Colors.red[50]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alertMessage!,
                    style: TextStyle(
                      color: isSuccess
                          ? (isDarkMode ? Colors.green[300] : Colors.green[800])
                          : (isDarkMode ? Colors.red[300] : Colors.red[800]),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Mode Dropdown
              Text('Action Type', style: _labelStyle(isDarkMode)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: notifType,
                style: _fieldTextStyle(isDarkMode),
                dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General Broadcast Notification')),
                  DropdownMenuItem(value: 'timetable_change', child: Text('Timetable Alert Broadcast')),
                  DropdownMenuItem(value: 'venue_change', child: Text('Venue Change Notification')),
                  DropdownMenuItem(value: 'reschedule', child: Text('Reschedule Timetable Slot (Auto-Notify)')),
                ],
                onChanged: (val) {
                  setState(() => notifType = val ?? 'general');
                  if (val == 'venue_change' && rooms.isEmpty && !isLoadingRooms) {
                    _fetchRooms();
                  }
                },
                decoration: _fieldDecoration(isDarkMode),
              ),
              const SizedBox(height: 16),

              // Unit Selector
              Text('Select Unit', style: _labelStyle(isDarkMode)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedUnitId,
                style: _fieldTextStyle(isDarkMode),
                dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                hint: Text('— Select unit —', style: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400])),
                items: units.map<DropdownMenuItem<String>>((LecturerUnitModel u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Text('${u.code} — ${u.name}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedUnitId = val);
                  if (val != null && isReschedule) {
                    _fetchSlotsForUnit(val);
                  }
                },
                decoration: _fieldDecoration(isDarkMode),
              ),
              const SizedBox(height: 16),


             // Conditional Fields based on Mode
              if (isReschedule) ...[
                Text('Select Class Slot to Reschedule', style: _labelStyle(isDarkMode)),
                const SizedBox(height: 6),
                isLoadingSlots
                    ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    : DropdownButtonFormField<String>(
                        value: selectedSlotId,
                        style: _fieldTextStyle(isDarkMode),
                        dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        hint: Text('— Choose a scheduled slot —', style: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400])),
                        items: availableSlotsForUnit.map<DropdownMenuItem<String>>((slot) {
                          final day = slot['day_of_week'] ?? '';
                          final start = slot['start_time'] ?? '';
                          final end = slot['end_time'] ?? '';
                          final room = slot['location'] ?? slot['room_display'] ?? 'TBA';
                          final unitCode = slot['unit_code'] ?? '';
                          final classGroup = (slot['class_group'] ?? '').toString();
                          final groupLabel = classGroup.isNotEmpty && classGroup.toUpperCase() != 'MAIN'
                              ? ' ($classGroup)'
                              : '';
                          return DropdownMenuItem<String>(
                            value: slot['id'].toString(),
                            child: Text(
                              '$unitCode$groupLabel | ${day.toUpperCase()} | $start - $end | Room: $room',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedSlotId = val),
                        decoration: _fieldDecoration(isDarkMode),
                      ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Day', style: _labelStyle(isDarkMode)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedDay,
                            style: _fieldTextStyle(isDarkMode),
                            dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                            items: days.map((d) => DropdownMenuItem(value: d, child: Text(d.toUpperCase()))).toList(),
                            onChanged: (val) => setState(() => selectedDay = val ?? 'mon'),
                            decoration: _fieldDecoration(isDarkMode),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.access_time, color: isDarkMode ? Colors.white : Colors.black87),
                        label: Text('Start: ${startTime.format(context)}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: startTime);
                          if (picked != null) setState(() => startTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.access_time_filled, color: isDarkMode ? Colors.white : Colors.black87),
                        label: Text('End: ${endTime.format(context)}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: endTime);
                          if (picked != null) setState(() => endTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Reason for Rescheduling', style: _labelStyle(isDarkMode)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: _fieldTextStyle(isDarkMode),
                  decoration: _fieldDecoration(isDarkMode, hintText: 'e.g., Medical appointment / Venue clashes...'),
                ),
              ] else ...[
                // Standard Notification Fields...
                Text('Notification Title', style: _labelStyle(isDarkMode)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  style: _fieldTextStyle(isDarkMode),
                  decoration: _fieldDecoration(isDarkMode, hintText: 'e.g. Class rescheduled to Friday'),
                ),
                const SizedBox(height: 16),
                Text('Message Body', style: _labelStyle(isDarkMode)),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: _fieldTextStyle(isDarkMode),
                  decoration: _fieldDecoration(isDarkMode, hintText: 'Write your message to students…'),
                ),
                if (notifType == 'venue_change') ...[
                  const SizedBox(height: 16),
                  Text('New Venue', style: _labelStyle(isDarkMode)),
                  const SizedBox(height: 6),
                  isLoadingRooms
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      : DropdownButtonFormField<String>(
                          value: selectedVenueId,
                          style: _fieldTextStyle(isDarkMode),
                          dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                          hint: Text('— Select a room —', style: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400])),
                          items: rooms.map<DropdownMenuItem<String>>((RoomModel r) {
                            return DropdownMenuItem<String>(value: r.id, child: Text(r.label));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedVenueId = val),
                          decoration: _fieldDecoration(isDarkMode),
                        ),
                  const SizedBox(height: 16),
                  Text('Expected Number of Students', style: _labelStyle(isDarkMode)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: expectedStudentsController,
                    keyboardType: TextInputType.number,
                    style: _fieldTextStyle(isDarkMode),
                    decoration: _fieldDecoration(isDarkMode, hintText: 'e.g. 45'),
                  ),
                ],
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending ? null : _submitAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LecturerColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isReschedule ? 'Submit Reschedule & Notify Students' : 'Send to Students',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAction() async {
    if (selectedUnitId == null) {
      setState(() {
        alertMessage = 'Please select a unit.';
        isSuccess = false;
      });
      return;
    }

    setState(() {
      isSending = true;
      alertMessage = null;
    });

    try {
      if (notifType == 'reschedule') {
        if (selectedSlotId == null) {
          throw Exception('Please select a timetable slot to reschedule.');
        }

        final response = await apiClient.dio.post(
          'timetable/slots/$selectedSlotId/reschedule/',
          data: {
            'day_of_week': selectedDay,
            'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
            'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
            'reason': reasonController.text.trim(),
          },
        );

        final notifiedData = response.data['notified'] ?? {};
        setState(() {
          isSuccess = true;
          alertMessage = '✓ Class rescheduled successfully! Notified ${notifiedData['recipients'] ?? 0} students via push & alert.';
          selectedSlotId = null;
          reasonController.clear();
        });
      } else {
        if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
          throw Exception('Please fill out both title and message fields.');
        }

        String? newVenueId;
        int? expectedStudents;
        if (notifType == 'venue_change') {
          if (selectedVenueId == null) {
            throw Exception('Please select the new venue.');
          }
          expectedStudents = int.tryParse(expectedStudentsController.text.trim());
          if (expectedStudents == null || expectedStudents <= 0) {
            throw Exception('Please enter a valid expected number of students.');
          }
          newVenueId = selectedVenueId;
        }

        final repo = ref.read(lecturerRepositoryProvider);
        final res = await repo.sendNotification(
          unitId: selectedUnitId!,
          notificationType: notifType,
          title: titleController.text.trim(),
          message: messageController.text.trim(),
          newVenueId: newVenueId,
          expectedStudents: expectedStudents,
        );

        setState(() {
          isSuccess = true;
          alertMessage = '✓ Successfully sent to ${res['recipients'] ?? 0} student(s).';
          titleController.clear();
          messageController.clear();
          selectedVenueId = null;
          expectedStudentsController.clear();
        });
      }
    } on VenueCapacityException catch (e) {
      final alternatives = e.suggestedRooms
          .map((r) => '${r['code']} (capacity ${r['capacity']})')
          .join(', ');
      setState(() {
        isSuccess = false;
        alertMessage = alternatives.isEmpty
            ? e.message
            : '${e.message} Try: $alternatives.';
      });
    } on DioException catch (e) {
      // Surface the backend's own message (e.g. a 409 room/lecturer clash
      // from the reschedule endpoint) instead of dumping the raw exception.
      final data = e.response?.data;
      String message;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        message = detail is List && detail.isNotEmpty ? detail.first.toString() : detail.toString();
      } else {
        message = e.message ?? 'Request failed. Please try again.';
      }
      setState(() {
        isSuccess = false;
        alertMessage = message;
      });
    } catch (e) {
      setState(() {
        isSuccess = false;
        alertMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => isSending = false);
    }
  }
}
