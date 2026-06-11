import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_constants.dart';

class AuthApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? nationality,
  }) async {
    final res = await _dio.post(ApiConstants.register, data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (nationality != null) 'nationality': nationality,
    });
    final data = res.data;
    await TokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    final data = res.data;
    await TokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(res.data);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final res = await _dio.patch(ApiConstants.profile, data: updates);
    return UserModel.fromJson(res.data);
  }

  Future<void> logout() async => TokenStorage.clear();
}
