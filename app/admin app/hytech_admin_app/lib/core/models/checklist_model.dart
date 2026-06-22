class ChecklistItemModel {
  final String id;
  final String caseId;
  final String documentType;
  final String itemType;
  final String personalizedDescription;
  final String? requirementDetail;
  final String status;
  final String? documentId;
  final int sortOrder;

  const ChecklistItemModel({
    required this.id,
    required this.caseId,
    required this.documentType,
    required this.itemType,
    required this.personalizedDescription,
    this.requirementDetail,
    required this.status,
    this.documentId,
    required this.sortOrder,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      ChecklistItemModel(
        id: json['id'],
        caseId: json['case_id'],
        documentType: json['document_type'],
        itemType: json['item_type'],
        personalizedDescription: json['personalized_description'],
        requirementDetail: json['requirement_detail'],
        status: json['status'],
        documentId: json['document_id'],
        sortOrder: json['sort_order'] ?? 0,
      );

  bool get isPending   => status == 'pending';
  bool get isValidated => status == 'validated';
  bool get isMandatory => itemType == 'mandatory';
}
