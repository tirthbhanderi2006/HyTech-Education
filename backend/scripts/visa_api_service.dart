import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Production-ready Flutter API Service for the HyTech Visa Copilot Backend.
/// Hand this file directly to your Flutter developer.
/// 
/// Dependecies:
/// Add `http` package to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   http: ^1.2.0
/// ```
class VisaApiService {
  final String baseUrl;
  String? _accessToken;

  VisaApiService({required this.baseUrl, String? initialToken}) {
    _accessToken = initialToken;
  }

  /// Sets the authentication token for subsequent requests
  void setToken(String token) {
    _accessToken = token;
  }

  /// Clears the authentication token
  void clearToken() {
    _accessToken = null;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Register a new candidate user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? nationality,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (nationality != null) 'nationality': nationality,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final authResp = AuthResponse.fromJson(data);
      _accessToken = authResp.accessToken;
      return authResp;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Login user and store token
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResp = AuthResponse.fromJson(data);
      _accessToken = authResp.accessToken;
      return authResp;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Fetch current user profile details
  Future<UserOut> getProfile() async {
    final url = Uri.parse('$baseUrl/api/v1/auth/me');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return UserOut.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update user profile details
  Future<UserOut> updateProfile(Map<String, dynamic> updateData) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/profile');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return UserOut.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ==========================================
  // CASE & CHECKLIST MANAGEMENT
  // ==========================================

  /// Create a new visa case and generate checklist items
  Future<CaseOut> createCase({
    required String destinationCountry,
    required String visaType,
    required String purpose,
    String? intendedTravelDate,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'destination_country': destinationCountry,
        'visa_type': visaType,
        'purpose': purpose,
        if (intendedTravelDate != null) 'intended_travel_date': intendedTravelDate,
      }),
    );

    if (response.statusCode == 201) {
      return CaseOut.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Fetch all cases of the current logged-in user
  Future<List<CaseOut>> listCases() async {
    final url = Uri.parse('$baseUrl/api/v1/cases/');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((item) => CaseOut.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get details of a specific case
  Future<CaseOut> getCase(String caseId) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/$caseId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return CaseOut.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get checklist items for a case
  Future<List<ChecklistItem>> getChecklist(String caseId) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/$caseId/checklist');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((item) => ChecklistItem.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update checklist item manually (e.g. status)
  Future<ChecklistItem> updateChecklistItem(
    String caseId,
    String checklistId, {
    String? status,
    String? personalizedDescription,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/$caseId/checklist/$checklistId');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        if (status != null) 'status': status,
        if (personalizedDescription != null) 'personalized_description': personalizedDescription,
      }),
    );

    if (response.statusCode == 200) {
      return ChecklistItem.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Run AI Eligibility check and return score/factors report
  Future<EligibilityResult> runEligibility(String caseId) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/$caseId/eligibility');
    final response = await http.post(url, headers: _headers);

    if (response.statusCode == 200) {
      return EligibilityResult.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Run AI Visa Rejection Risk Analysis report
  Future<RiskAnalysisResult> runRiskAnalysis(String caseId) async {
    final url = Uri.parse('$baseUrl/api/v1/cases/$caseId/risk');
    final response = await http.post(url, headers: _headers);

    if (response.statusCode == 200) {
      return RiskAnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ==========================================
  // DOCUMENT MANAGEMENT
  // ==========================================

  /// Upload a document file (PDF or Image)
  Future<DocumentOut> uploadDocument({
    required String caseId,
    required String documentType,
    required List<int> fileBytes,
    required String filename,
    String? intendedTravelDate,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/documents/upload');
    final request = http.MultipartRequest('POST', url);

    // Add authorization header
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Add form text fields
    request.fields['case_id'] = caseId;
    request.fields['document_type'] = documentType;
    if (intendedTravelDate != null) {
      request.fields['intended_travel_date'] = intendedTravelDate;
    }

    // Add file bytes
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return DocumentOut.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get details of documents uploaded for a specific case
  Future<List<DocumentOut>> listCaseDocuments(String caseId) async {
    final url = Uri.parse('$baseUrl/api/v1/documents/case/$caseId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((item) => DocumentOut.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Fetch validation details for a specific document
  Future<DocumentValidationResult> getDocumentValidation(String documentId) async {
    final url = Uri.parse('$baseUrl/api/v1/documents/$documentId/validation');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return DocumentValidationResult.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  /// Fetch user notifications
  Future<List<NotificationItem>> listNotifications() async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((item) => NotificationItem.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/$notificationId/read');
    final response = await http.patch(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

// ============================================================================
// DART MODEL DATA STRUCTURES (DTOs)
// ============================================================================

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException(Status: $statusCode, Body: $body)';
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserOut user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      user: UserOut.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserOut {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? nationality;
  final String? passportExpiry;
  final String? educationLevel;
  final String subscriptionTier;
  final bool isVerified;
  final String createdAt;

  UserOut({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.nationality,
    this.passportExpiry,
    this.educationLevel,
    required this.subscriptionTier,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserOut.fromJson(Map<String, dynamic> json) {
    return UserOut(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      nationality: json['nationality'] as String?,
      passportExpiry: json['passport_expiry'] as String?,
      educationLevel: json['education_level'] as String?,
      subscriptionTier: json['subscription_tier'] as String,
      isVerified: json['is_verified'] as bool,
      createdAt: json['created_at'] as String,
    );
  }
}

class CaseOut {
  final String id;
  final String userId;
  final String? destinationCountry;
  final String? visaType;
  final String? purpose;
  final String status;
  final double? readinessScore;
  final double? riskScore;
  final double? eligibilityScore;
  final String createdAt;

  CaseOut({
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

  factory CaseOut.fromJson(Map<String, dynamic> json) {
    return CaseOut(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      destinationCountry: json['destination_country'] as String?,
      visaType: json['visa_type'] as String?,
      purpose: json['purpose'] as String?,
      status: json['status'] as String,
      readinessScore: (json['readiness_score'] as num?)?.toDouble(),
      riskScore: (json['risk_score'] as num?)?.toDouble(),
      eligibilityScore: (json['eligibility_score'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
    );
  }
}

class ChecklistItem {
  final String id;
  final String caseId;
  final String documentType;
  final String itemType;
  final String personalizedDescription;
  final String? requirementDetail;
  final String status;
  final String? documentId;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  ChecklistItem({
    required this.id,
    required this.caseId,
    required this.documentType,
    required this.itemType,
    required this.personalizedDescription,
    this.requirementDetail,
    required this.status,
    this.documentId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      documentType: json['document_type'] as String,
      itemType: json['item_type'] as String,
      personalizedDescription: json['personalized_description'] as String,
      requirementDetail: json['requirement_detail'] as String?,
      status: json['status'] as String,
      documentId: json['document_id'] as String?,
      sortOrder: json['sort_order'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class DocumentOut {
  final String id;
  final String caseId;
  final String documentType;
  final String originalFilename;
  final String status;
  final double? healthScore;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? validationFlags;
  final List<String>? suggestedFixes;
  final String uploadedAt;
  final String? validatedAt;

  DocumentOut({
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
    this.validatedAt,
  });

  factory DocumentOut.fromJson(Map<String, dynamic> json) {
    return DocumentOut(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      documentType: json['document_type'] as String,
      originalFilename: json['original_filename'] as String,
      status: json['status'] as String,
      healthScore: (json['health_score'] as num?)?.toDouble(),
      extractedData: json['extracted_data'] != null ? Map<String, dynamic>.from(json['extracted_data'] as Map) : null,
      validationFlags: json['validation_flags'] != null ? Map<String, dynamic>.from(json['validation_flags'] as Map) : null,
      suggestedFixes: json['suggested_fixes'] != null ? List<String>.from(json['suggested_fixes'] as List) : null,
      uploadedAt: json['uploaded_at'] as String,
      validatedAt: json['validated_at'] as String?,
    );
  }
}

class DocumentValidationResult {
  final String documentId;
  final double healthScore;
  final Map<String, dynamic> extractedFields;
  final List<dynamic> flags;
  final List<String> suggestedFixes;
  final bool isValid;

  DocumentValidationResult({
    required this.documentId,
    required this.healthScore,
    required this.extractedFields,
    required this.flags,
    required this.suggestedFixes,
    required this.isValid,
  });

  factory DocumentValidationResult.fromJson(Map<String, dynamic> json) {
    return DocumentValidationResult(
      documentId: json['document_id'] as String,
      healthScore: (json['health_score'] as num).toDouble(),
      extractedFields: Map<String, dynamic>.from(json['extracted_fields'] as Map),
      flags: json['flags'] as List<dynamic>,
      suggestedFixes: List<String>.from(json['suggested_fixes'] as List),
      isValid: json['is_valid'] as bool,
    );
  }
}

class EligibilityResult {
  final double overallScore;
  final String category;
  final Map<String, dynamic> factors;
  final List<dynamic> gapAnalysis;
  final List<String> recommendedActions;
  final String explainability;

  EligibilityResult({
    required this.overallScore,
    required this.category,
    required this.factors,
    required this.gapAnalysis,
    required this.recommendedActions,
    required this.explainability,
  });

  factory EligibilityResult.fromJson(Map<String, dynamic> json) {
    return EligibilityResult(
      overallScore: (json['overall_score'] as num).toDouble(),
      category: json['category'] as String,
      factors: Map<String, dynamic>.from(json['factors'] as Map),
      gapAnalysis: json['gap_analysis'] as List<dynamic>,
      recommendedActions: List<String>.from(json['recommended_actions'] as List),
      explainability: json['explainability'] as String,
    );
  }
}

class RiskAnalysisResult {
  final double riskScore;
  final String riskCategory;
  final List<dynamic> topRiskFactors;
  final List<dynamic> improvementRecommendations;
  final String disclaimer;

  RiskAnalysisResult({
    required this.riskScore,
    required this.riskCategory,
    required this.topRiskFactors,
    required this.improvementRecommendations,
    required this.disclaimer,
  });

  factory RiskAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RiskAnalysisResult(
      riskScore: (json['risk_score'] as num).toDouble(),
      riskCategory: json['risk_category'] as String,
      topRiskFactors: json['top_risk_factors'] as List<dynamic>,
      improvementRecommendations: json['improvement_recommendations'] as List<dynamic>,
      disclaimer: json['disclaimer'] as String,
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String sentAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool,
      sentAt: json['sent_at'] as String,
    );
  }
}
