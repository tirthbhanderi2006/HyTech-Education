class ApiConstants {
  // Change to your machine IP when testing on physical device
  // Use http://10.0.2.2:8000 for Android emulator
  // Use http://localhost:8000 for iOS simulator / web
  static const String baseUrl = 'http://10.232.70.85:8000/api/v1';

  // Auth
  static const String register   = '/auth/register';
  static const String login      = '/auth/login';
  static const String me         = '/auth/me';
  static const String profile    = '/auth/profile';
  static const String users      = '/auth/users';
  static const String adminStats = '/auth/admin/stats';

  // Cases
  static const String cases         = '/cases/';
  static String caseById(String id) => '/cases/$id';
  static String eligibility(String id) => '/cases/$id/eligibility';
  static String risk(String id)        => '/cases/$id/risk';
  static String checklist(String id)   => '/cases/$id/checklist';
  static String checklistItem(String caseId, String itemId) =>
      '/cases/$caseId/checklist/$itemId';

  // Documents
  static const String uploadDocument  = '/documents/upload';
  static String caseDocuments(String caseId) => '/documents/case/$caseId';
  static String documentValidation(String docId) => '/documents/$docId/validation';

  // Notifications
  static const String notifications = '/notifications';
  static String markRead(String id) => '/notifications/$id/read';
}
