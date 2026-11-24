import 'professional.dart';

/// Demande du soignant sur son planning. Le planning est tenu par l'agence : rien ne change
/// tant que la coordination n'a pas accepté.
class ScheduleRequest {
  const ScheduleRequest({
    required this.id,
    required this.kind,
    required this.status,
    this.startsOn,
    this.endsOn,
    this.slots = const <AvailabilitySlot>[],
    this.note,
    this.decisionNote,
  });

  factory ScheduleRequest.fromJson(Map<String, dynamic> json) {
    final slots = json['slots'];

    return ScheduleRequest(
      id: json['id'] as String,
      kind: (json['kind'] as String?) ?? kindUnavailability,
      status: (json['status'] as String?) ?? statusPending,
      startsOn: DateTime.tryParse((json['starts_on'] as String?) ?? ''),
      endsOn: DateTime.tryParse((json['ends_on'] as String?) ?? ''),
      slots: slots is List
          ? slots.whereType<Map<String, dynamic>>().map(AvailabilitySlot.fromJson).toList()
          : const <AvailabilitySlot>[],
      note: json['note'] as String?,
      decisionNote: json['decision_note'] as String?,
    );
  }

  static const String kindWeekly = 'weekly';
  static const String kindUnavailability = 'unavailability';

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRefused = 'refused';
  static const String statusCancelled = 'cancelled';

  final String id;

  /// `weekly` (nouvelle semaine type) ou `unavailability` (indisponibilité datée).
  final String kind;

  /// `pending`, `accepted`, `refused` ou `cancelled`.
  final String status;

  /// Premier et dernier jour d'une indisponibilité, bornes comprises.
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// Semaine proposée.
  final List<AvailabilitySlot> slots;
  final String? note;

  /// Motif donné par la coordination en cas de refus.
  final String? decisionNote;

  bool get isPending => status == statusPending;

  bool get isWeekly => kind == kindWeekly;
}
