class CaseModel {
  final String id;
  final String userId;
  final String? destinationCountry;
  final String? visaType;
  final String? purpose;
  final String status;
  final double? readinessScore;
  final double? riskScore;
  final double? eligibilityScore;
  final DateTime createdAt;

  const CaseModel({
    required this.id,
    required this.userId,
    this.destinationCountry,
    this.visaType,
    this.purpose,
    required this.status,
    this.readinessScore,
    this.riskScore,
    this.eligibilityScore,
    required this.createdAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: json['id'],
        userId: json['user_id'],
        destinationCountry: json['destination_country'],
        visaType: json['visa_type'],
        purpose: json['purpose'],
        status: json['status'] ?? 'discovery',
        readinessScore: (json['readiness_score'] as num?)?.toDouble(),
        riskScore: (json['risk_score'] as num?)?.toDouble(),
        eligibilityScore: (json['eligibility_score'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at']),
      );

  String get readinessLabel {
    final s = readinessScore ?? 0;
    if (s >= 80) return 'Ready';
    if (s >= 50) return 'In Progress';
    return 'Incomplete';
  }
}
