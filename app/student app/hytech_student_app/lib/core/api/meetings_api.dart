import 'package:dio/dio.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class MeetingsApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<MeetingModel>> getMeetings() async {
    final res = await _dio.get('/meetings/');
    return (res.data as List).map((e) => MeetingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MeetingModel> bookMeeting({
    required String counselorId,
    required DateTime startTime,
    required DateTime endTime,
    String? caseId,
    String? notes,
  }) async {
    final res = await _dio.post('/meetings/book', data: {
      'counselor_id': counselorId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (caseId != null) 'case_id': caseId,
      if (notes != null) 'notes': notes,
    });
    return MeetingModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MeetingModel> rescheduleMeeting(
      String meetingId, DateTime start, DateTime end) async {
    final res = await _dio.patch('/meetings/$meetingId/reschedule', data: {
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
    });
    return MeetingModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancelMeeting(String meetingId) async {
    await _dio.delete('/meetings/$meetingId');
  }

  Future<List<UserModel>> getCounselors() async {
    final res = await _dio.get('/meetings/counselors');
    return (res.data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
