class MeetingModel {
  final String id;
  final String? caseId;
  final String candidateId;
  final String counselorId;
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime endTime;
  final String? meetLink;
  final String status;
  final DateTime createdAt;

  const MeetingModel({
    required this.id,
    this.caseId,
    required this.candidateId,
    required this.counselorId,
    required this.title,
    this.notes,
    required this.startTime,
    required this.endTime,
    this.meetLink,
    required this.status,
    required this.createdAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) => MeetingModel(
        id: json['id'] as String,
        caseId: json['case_id'] as String?,
        candidateId: json['candidate_id'] as String,
        counselorId: json['counselor_id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String?,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        meetLink: json['meet_link'] as String?,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isConfirmed  => status == 'confirmed' || status == 'rescheduled';
  bool get isCancelled  => status == 'cancelled';
  bool get canJoin      => meetLink != null && isConfirmed;
}
