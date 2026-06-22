import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class NotificationsApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get(ApiConstants.notifications);
    return (res.data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch(ApiConstants.markRead(notificationId));
  }
}
