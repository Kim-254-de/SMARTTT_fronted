import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../domain/models/lecturer_dashboard_model.dart'; // Correct relative path
import '../widgets/lecturer_colors.dart';

class LecturerNotificationTab extends ConsumerStatefulWidget {
  const LecturerNotificationTab({super.key});

  @override
  ConsumerState<LecturerNotificationTab> createState() => _LecturerNotificationTabState();
}

class _LecturerNotificationTabState extends ConsumerState<LecturerNotificationTab> {
  String? selectedUnitId;
  String notifType = 'general';
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  bool isSending = false;
  String? alertMessage;
  bool isSuccess = false;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(lecturerDashboardProvider).dashboard;
    final units = dashboard?.units ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Send Notification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alertMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alertMessage!,
                    style: TextStyle(color: isSuccess ? Colors.green[800] : Colors.red[800], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Select Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedUnitId,
                hint: const Text('— Select unit —'),
                items: units.map<DropdownMenuItem<String>>((LecturerUnitModel u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Text('${u.code} — ${u.name}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedUnitId = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Notification Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Class rescheduled to Friday',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Message Body', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your message to students…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: notifType,
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'timetable_change', child: Text('Timetable Change')),
                  DropdownMenuItem(value: 'sync_reminder', child: Text('Sync Reminder')),
                ],
                onChanged: (val) => setState(() => notifType = val ?? 'general'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending ? null : _sendNotificationAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LecturerColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send to Students', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotificationAction() async {
    if (selectedUnitId == null || titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
      setState(() {
        alertMessage = 'Please fill out all fields and select a unit.';
        isSuccess = false;
      });
      return;
    }

    setState(() {
      isSending = true;
      alertMessage = null;
    });

    try {
      final repo = ref.read(lecturerRepositoryProvider);
      final res = await repo.sendNotification(
        unitId: selectedUnitId!,
        notificationType: notifType,
        title: titleController.text.trim(),
        message: messageController.text.trim(),
      );

      setState(() {
        isSuccess = true;
        alertMessage = '✓ Successfully sent to ${res['recipients'] ?? 0} student(s).';
        titleController.clear();
        messageController.clear();
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
