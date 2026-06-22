import 'dart:io';
import 'package:dio/dio.dart';
import '../models/document_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class DocumentsApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<DocumentModel> uploadDocument({
    required String caseId,
    required String documentType,
    required File file,
    String? intendedTravelDate,
  }) async {
    final formData = FormData.fromMap({
      'case_id': caseId,
      'document_type': documentType,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      if (intendedTravelDate != null) 'intended_travel_date': intendedTravelDate,
    });

    final res = await _dio.post(
      ApiConstants.uploadDocument,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return DocumentModel.fromJson(res.data);
  }

  Future<List<DocumentModel>> getCaseDocuments(String caseId) async {
    final res = await _dio.get(ApiConstants.caseDocuments(caseId));
    return (res.data as List).map((e) => DocumentModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getValidationResult(String documentId) async {
    final res = await _dio.get(ApiConstants.documentValidation(documentId));
    return Map<String, dynamic>.from(res.data);
  }
}
