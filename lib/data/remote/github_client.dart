import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/github_constants.dart';

class GitHubClient {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'github_access_token';

  Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await _dio.post(
      'https://github.com/login/device/code',
      queryParameters: {
        'client_id': GitHubConstants.clientId,
        'scope': GitHubConstants.scopes,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data;
  }

  Future<String?> pollForToken(String deviceCode, int interval) async {
    while (true) {
      await Future.delayed(Duration(seconds: interval));
      try {
        final response = await _dio.post(
          'https://github.com/login/oauth/access_token',
          queryParameters: {
            'client_id': GitHubConstants.clientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
          options: Options(headers: {'Accept': 'application/json'}),
        );

        final data = response.data;
        if (data['access_token'] != null) {
          final token = data['access_token'];
          await _storage.write(key: _tokenKey, value: token);
          return token;
        } else if (data['error'] == 'authorization_pending') {
          // Keep polling
          continue;
        } else if (data['error'] == 'slow_down') {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        } else {
          // expired_token, access_denied, etc.
          return null;
        }
      } catch (e) {
        return null;
      }
    }
  }

  Future<bool> pushReport(String owner, String repo, Map<String, dynamic> reportData) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;

    try {
      // Create a unique filename based on date
      final filename = '${DateTime.now().toIso8601String().split('T').first}_scan-report.json';
      
      await _dio.put(
        'https://api.github.com/repos/$owner/$repo/contents/.devgate/scan-reports/$filename',
        data: {
          'message': 'DevGate: security scan $filename',
          'content': base64Encode(utf8.encode(jsonEncode(reportData))),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to push report: $e');
      return false;
    }
  }

  Future<bool> createRepository(String name, {bool private = true}) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;

    try {
      await _dio.post(
        'https://api.github.com/user/repos',
        data: {
          'name': name,
          'private': private,
          'auto_init': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to create repo: $e');
      return false;
    }
  }
}
