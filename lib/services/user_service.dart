import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';

class UserService {
  static String? _cachedToken;

  // جلب التوكن من التخزين
  static Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // حفظ التوكن بعد تسجيل الدخول
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _cachedToken = token;
  }

  // داخل UserService.dart
  static Future<Map<String, dynamic>?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await checkConnectivity()) throw Exception('No internet connection');

    final body = {
      "current_password": currentPassword.trim(),
      "new_password": newPassword.trim(),
    };

    final response = await http.put(
      Uri.parse(
        ApiConstants.updateProfile,
      ), // نفس endpoint الخاص بـ updateProfile
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    print('UpdatePassword Status: ${response.statusCode}');
    print('UpdatePassword Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _handleError('updatePassword', response);
    return null;
  }

  // مسح التوكن عند تسجيل الخروج
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _cachedToken = null;
  }

  // التأكد من صلاحية التوكن
  static Future<bool> isTokenValid() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        final exp = payload['exp'];
        if (exp != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          return DateTime.now().isBefore(expiry);
        }
      }
    } catch (_) {}
    return true;
  }

  // هيدرز للطلبات المحمية
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // التأكد من وجود إنترنت
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // جلب بيانات المستخدم الحالي
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      if (!await checkConnectivity()) throw Exception('No internet connection');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ User not logged in');
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.getCurrentUser),
        headers: await _getHeaders(),
      );

      print('GetCurrentUser Status: ${response.statusCode}');
      print('GetCurrentUser Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _handleError('getCurrentUser', response);
        return null;
      }
    } catch (e) {
      print('💥 Error in getCurrentUser: $e');
      return null;
    }
  }

  // تحديث بيانات المستخدم
  static Future<Map<String, dynamic>?> updateProfile({
    String? email,
    String? phone,
    String? address,
    String? currentPassword,
    String? newPassword,
  }) async {
    if (!await checkConnectivity()) throw Exception('No internet connection');

    final body = <String, dynamic>{};
    if (email?.isNotEmpty == true) body['email'] = email!.trim();
    if (phone?.isNotEmpty == true) body['phone'] = phone!.trim();
    if (address?.isNotEmpty == true) body['address'] = address!.trim();
    if (currentPassword?.isNotEmpty == true)
      body['current_password'] = currentPassword!.trim();
    if (newPassword?.isNotEmpty == true)
      body['new_password'] = newPassword!.trim();

    if (body.isEmpty) return null;

    final response = await http.put(
      Uri.parse(ApiConstants.updateProfile),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _handleError('updateProfile', response);
    return null;
  }

  // حذف الحساب
  static Future<bool> deleteAccount() async {
    if (!await checkConnectivity()) throw Exception('No internet connection');

    final response = await http.delete(
      Uri.parse(ApiConstants.deleteAccount),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      await clearToken();
      return true;
    }

    _handleError('deleteAccount', response);
    return false;
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    await clearToken();
  }

  // معالجة الأخطاء
  static void _handleError(String operation, http.Response response) {
    print('⚠️ $operation failed with status: ${response.statusCode}');
    if (response.statusCode == 401) clearToken();
  }
}
