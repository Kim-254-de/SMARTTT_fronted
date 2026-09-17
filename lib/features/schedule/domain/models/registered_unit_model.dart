/// A unit the student is registered for this term, from
/// GET /courses/my-courses/. Distinct from [TimetableSessionModel], which
/// represents a scheduled class session — this represents the registration
/// record itself, including whether the student still needs to pick which
/// elective/practical group they're in for it.
class RegisteredUnitModel {
  final String id; // StudentUnit id — required by PATCH .../group/
  final String unitCode;
  final String unitName;
  final String? classGroup; // null/empty = not split, or not picked yet
  final List<String> availableGroups; // empty = unit isn't split into groups

  RegisteredUnitModel({
    required this.id,
    required this.unitCode,
    required this.unitName,
    this.classGroup,
    this.availableGroups = const [],
  });

  /// True when this unit is split into groups and the student hasn't
  /// picked theirs yet — the schedule falls back to showing every group's
  /// sessions until they do (see apps.schedule.services.get_matching_slots
  /// on the backend).
  bool get needsGroupSelection =>
      availableGroups.isNotEmpty && (classGroup == null || classGroup!.isEmpty);

  factory RegisteredUnitModel.fromJson(Map<String, dynamic> json) {
    return RegisteredUnitModel(
      id: json['id']?.toString() ?? '',
      unitCode: json['unit_code']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      classGroup: (json['class_group'] as String?)?.isEmpty == true
          ? null
          : json['class_group'] as String?,
      availableGroups: (json['available_groups'] as List?)
              ?.map((g) => g.toString())
              .toList() ??
          const [],
    );
  }
}
