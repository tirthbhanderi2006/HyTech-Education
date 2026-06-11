import 'package:dio/dio.dart';
import '../models/case_model.dart';
import '../models/checklist_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class CasesApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<CaseModel> createCase({
    required String destinationCountry,
    required String visaType,
    required String purpose,
    String? intendedTravelDate,
  }) async {
    final res = await _dio.post(ApiConstants.cases, data: {
      'destination_country': destinationCountry,
      'visa_type': visaType,
      'purpose': purpose,
      if (intendedTravelDate != null) 'intended_travel_date': intendedTravelDate,
    });
    return CaseModel.fromJson(res.data);
  }

  Future<List<CaseModel>> listCases() async {
    final res = await _dio.get(ApiConstants.cases);
    return (res.data as List).map((e) => CaseModel.fromJson(e)).toList();
  }

  Future<CaseModel> getCase(String caseId) async {
    final res = await _dio.get(ApiConstants.caseById(caseId));
    return CaseModel.fromJson(res.data);
  }

  Future<Map<String, dynamic>> runEligibility(String caseId) async {
    final res = await _dio.post(ApiConstants.eligibility(caseId));
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> runRiskAnalysis(String caseId) async {
    final res = await _dio.post(ApiConstants.risk(caseId));
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<ChecklistItemModel>> getChecklist(String caseId) async {
    final res = await _dio.get(ApiConstants.checklist(caseId));
    return (res.data as List)
        .map((e) => ChecklistItemModel.fromJson(e))
        .toList();
  }

  Future<ChecklistItemModel> updateChecklistItem(
    String caseId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    final res = await _dio.patch(
      ApiConstants.checklistItem(caseId, itemId),
      data: updates,
    );
    return ChecklistItemModel.fromJson(res.data);
  }
}
