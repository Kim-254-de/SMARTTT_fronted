import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/lecturer_dashboard_provider.dart';
import '../../data/lecturer_repository.dart';
import '../../domain/models/lecturer_dashboard_model.dart';
import '../widgets/lecturer_colors.dart';

class _NotificationTypeOption {
  final String value;
  final String label;
  final IconData icon;
  const _NotificationTypeOption(this.value, this.label, this.icon);
}

const _typeOptions = [
  _NotificationTypeOption('general', 'General', Iconsax.info_circle),
  _NotificationTypeOption('timetable_change', 'Timetable Change', Iconsax.calendar_edit),
  _NotificationTypeOption('sync_reminder', 'Sync Reminder', Iconsax.refresh),
  _NotificationTypeOption('venue_change', 'Venue Change', Iconsax.location),
];

class LecturerProfileTab extends ConsumerStatefulWidget {
  const LecturerProfileTab({super.key});

  @override
  ConsumerState<LecturerProfileTab> createState() => _LecturerProfileTabState();
}

class _LecturerProfileTabState extends ConsumerState<LecturerProfileTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _expectedStudentsController = TextEditingController();

  LecturerUnitModel? _selectedUnit;
  String _selectedType = 'general';
  RoomModel? _selectedVenue;
  List<RoomModel> _rooms = [];
  bool _roomsLoading = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _expectedStudentsController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomsIfNeeded() async {
    if (_rooms.isNotEmpty || _roomsLoading) return;
    setState(() => _roomsLoading = true);
    try {
      final rooms = await ref.read(lecturerRepositoryProvider).fetchRooms();
      if (mounted) setState(() => _rooms = rooms);
    } catch (_) {
      // Silently ignore — the dropdown will just stay empty and the field is
      // required, so the person will notice and can retry by reselecting the type.
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  Future<void> _handleSend() async {
    if (_selectedUnit == null) {
      _showSnack('Please select a unit.', isError: true);
      return;
    }
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showSnack('Please enter a title and message.', isError: true);
      return;
    }
    String? newVenueId;
    int? expectedStudents;
    if (_selectedType == 'venue_change') {
      if (_selectedVenue == null || _expectedStudentsController.text.trim().isEmpty) {
        _showSnack('Please select the new venue and expected number of students.', isError: true);
        return;
      }
      newVenueId = _selectedVenue!.id;
      expectedStudents = int.tryParse(_expectedStudentsController.text.trim());
      if (expectedStudents == null) {
        _showSnack('Expected students must be a number.', isError: true);
        return;
      }
    }

    setState(() => _sending = true);
    try {
      final result = await ref.read(lecturerRepositoryProvider).sendNotification(
            unitId: _selectedUnit!.id,
            notificationType: _selectedType,
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            newVenueId: newVenueId,
            expectedStudents: expectedStudents,
          );
      if (!mounted) return;
      final recipients = result['recipients'] ?? 0;
      _showSnack('Sent to $recipients student${recipients == 1 ? '' : 's'}.');
      _titleController.clear();
      _messageController.clear();
      _expectedStudentsController.clear();
      setState(() {
        _selectedVenue = null;
      });
    } on VenueCapacityException catch (e) {
      if (!mounted) return;
      _showCapacityDialog(e);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : LecturerColors.green),
    );
  }

  void _showCapacityDialog(VenueCapacityException e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("That room won't fit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.message),
            if (e.suggestedRooms.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Try one of these instead:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...e.suggestedRooms.map((r) => Text('• ${r['code']} (capacity ${r['capacity']})')),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final user = authState.user;
    final dashboard = dashboardState.dashboard;

    final initials = (user?.fullName ?? '?')
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile info card ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: LecturerColors.navy,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (dashboard?.lecturer?.staffId.isNotEmpty == true)
                        Text('STAFF-${dashboard!.lecturer!.staffId}',
                            style: const TextStyle(color: LecturerColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                      if (dashboard?.lecturer?.department.isNotEmpty == true)
                        Text(dashboard!.lecturer!.department, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pushNamed('edit-profile'),
                  icon: const Icon(Iconsax.edit),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Email', value: user?.email ?? ''),
                const SizedBox(height: 10),
                _InfoRow(label: 'Department', value: dashboard?.lecturer?.department ?? ''),
                const SizedBox(height: 10),
                _InfoRow(label: 'Staff ID', value: dashboard?.lecturer?.staffId ?? user?.universityId ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Send Notification form ──────────────────────────────────────
          Row(
            children: const [
              Icon(Iconsax.notification, size: 18, color: LecturerColors.navy),
              SizedBox(width: 8),
              Text('Send Notification to Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          const Text('UNIT', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _FieldContainer(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<LecturerUnitModel>(
                value: _selectedUnit,
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                hint: const Text('— Select unit —'),
                items: (dashboard?.units ?? [])
                    .map((u) => DropdownMenuItem(value: u, child: Text('${u.code} — ${u.name}', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (u) => setState(() => _selectedUnit = u),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('TYPE', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: _typeOptions.map((opt) {
              final selected = _selectedType == opt.value;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = opt.value);
                  if (opt.value == 'venue_change') _loadRoomsIfNeeded();
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? LecturerColors.navy : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? LecturerColors.navy : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(opt.icon, size: 15, color: selected ? Colors.white : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          opt.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (_selectedType == 'venue_change') ...[
            const Text('NEW VENUE', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _FieldContainer(
              child: _roomsLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Loading rooms…'),
                      ]),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<RoomModel>(
                        value: _selectedVenue,
                        isExpanded: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                        hint: const Text('— Select new room —'),
                        items: _rooms.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                        onChanged: (r) => setState(() => _selectedVenue = r),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            const Text('EXPECTED STUDENTS', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _FieldContainer(
              child: TextField(
                controller: _expectedStudentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'e.g. 44'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text('TITLE', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _FieldContainer(
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'e.g. Class rescheduled to Friday'),
            ),
          ),
          const SizedBox(height: 16),

          const Text('MESSAGE', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _FieldContainer(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write your message to students…'),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _sending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: LecturerColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send to Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldContainer extends StatelessWidget {
  final Widget child;
  const _FieldContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }
}
