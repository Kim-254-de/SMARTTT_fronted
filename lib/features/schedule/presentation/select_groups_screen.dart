import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/registered_unit_model.dart';
import 'providers/timetable_provider.dart';

/// Lets the student pick which elective/practical group they're in for each
/// registered unit that's actually split into more than one (e.g. "GR B" vs
/// "GR C"). Different unit pools within the same stream can use unrelated
/// group letters at once (see TimetableSlot.stream on the backend), so this
/// is asked per-unit rather than once for the whole stream — unlike the
/// stream picker on the preferences screen.
///
/// Reached either right after a sync (when there's something to resolve) or
/// any time from the schedule screen, to change a previous pick.
class SelectGroupsScreen extends ConsumerStatefulWidget {
  const SelectGroupsScreen({super.key});

  @override
  ConsumerState<SelectGroupsScreen> createState() => _SelectGroupsScreenState();
}

class _SelectGroupsScreenState extends ConsumerState<SelectGroupsScreen> {
  bool _isLoading = true;
  final Set<String> _savingIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await ref.read(timetableProvider.notifier).fetchMySchedule();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pick(RegisteredUnitModel unit, String group) async {
    setState(() => _savingIds.add(unit.id));
    final success = await ref.read(timetableProvider.notifier).setUnitGroup(
          studentUnitId: unit.id,
          classGroup: group,
        );
    if (!mounted) return;
    setState(() => _savingIds.remove(unit.id));
    if (!success) {
      final error = ref.read(timetableProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not save your group.'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registeredUnits = ref.watch(timetableProvider).registeredUnits;
    final splitUnits = registeredUnits.where((u) => u.availableGroups.isNotEmpty).toList();
    final pendingCount = splitUnits.where((u) => u.needsGroupSelection).length;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Your Class Groups', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Iconsax.people, color: AppTheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pendingCount > 0
                                ? 'Some of your units are split into more than one '
                                  'class group (e.g. practicals). Pick yours below so '
                                  'your schedule shows only your own sessions.'
                                : 'These are your units that are split into groups. '
                                  'Tap a different group any time to change your pick.',
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
                  const SizedBox(height: 20),
                  if (splitUnits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Column(
                        children: [
                          Icon(Iconsax.tick_circle, size: 40, color: AppTheme.getTextSecondary(context)),
                          const SizedBox(height: 12),
                          Text(
                            'None of your registered units are split into groups',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.getTextSecondary(context)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...splitUnits.map(
                      (unit) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _UnitGroupCard(
                          unit: unit,
                          isSaving: _savingIds.contains(unit.id),
                          onPick: (group) => _pick(unit, group),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _UnitGroupCard extends StatelessWidget {
  const _UnitGroupCard({
    required this.unit,
    required this.isSaving,
    required this.onPick,
  });

  final RegisteredUnitModel unit;
  final bool isSaving;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final needsPick = unit.needsGroupSelection;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: needsPick ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.getBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.unitName.isNotEmpty ? unit.unitName : unit.unitCode,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unit.unitCode,
                  style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            needsPick ? 'Pick your group' : 'Your group: ${unit.classGroup}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: needsPick ? AppTheme.primary : AppTheme.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          if (isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unit.availableGroups.map((group) {
                final isSelected = unit.classGroup == group;
                return ChoiceChip(
                  label: Text(group),
                  selected: isSelected,
                  onSelected: (_) => onPick(group),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
