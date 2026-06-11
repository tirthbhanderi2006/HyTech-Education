class DocumentModel {
  final String id;
  final String caseId;
  final String documentType;
  final String originalFilename;
  final String status;
  final double? healthScore;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? validationFlags;
  final List<dynamic>? suggestedFixes;
  final DateTime uploadedAt;

  const DocumentModel({
    required this.id,
    required this.caseId,
    required this.documentType,
    required this.originalFilename,
    required this.status,
    this.healthScore,
    this.extractedData,
    this.validationFlags,
    this.suggestedFixes,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'],
        caseId: json['case_id'],
        documentType: json['document_type'],
        originalFilename: json['original_filename'],
        status: json['status'],
        healthScore: (json['health_score'] as num?)?.toDouble(),
        extractedData: json['extracted_data'],
        validationFlags: json['validation_flags'],
        suggestedFixes: json['suggested_fixes'],
        uploadedAt: DateTime.parse(json['uploaded_at']),
      );

  bool get isValidated => status == 'validated';
  bool get isRejected  => status == 'rejected';

  String get healthLabel {
    final s = healthScore ?? 0;
    if (s >= 80) return 'Good';
    if (s >= 60) return 'Acceptable';
    return 'Needs Fix';
  }
}
