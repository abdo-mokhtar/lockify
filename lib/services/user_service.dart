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

  // تحديث كلمة المرور فقط
  static Future<Map<String, dynamic>?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!await checkConnectivity()) {
        throw Exception('No internet connection');
      }

      final body = {
        "current_password": currentPassword.trim(),
        "new_password": newPassword.trim(),
      };

      print('📤 UpdatePassword request body: $body');

      final response = await http
          .put(
            Uri.parse(ApiConstants.updateProfile),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('UpdatePassword Status: ${response.statusCode}');
      print('UpdatePassword Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 422) {
        // معالجة أخطاء التحقق
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Validation error';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.toString();
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Invalid data provided');
        }
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired. Please login again.');
      } else {
        _handleError('updatePassword', response);
        throw Exception(
          'Failed to update password. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error in updatePassword: $e');
      rethrow;
    }
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
      if (!await checkConnectivity()) {
        throw Exception('No internet connection');
      }

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ User not logged in');
        throw Exception('User not logged in');
      }

      final response = await http
          .get(
            Uri.parse(ApiConstants.getCurrentUser),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('GetCurrentUser Status: ${response.statusCode}');
      print('GetCurrentUser Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        await clearToken(); // مسح التوكن إذا انتهت صلاحيته
        throw Exception('Session expired. Please login again.');
      } else {
        _handleError('getCurrentUser', response);
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      print('💥 Error in getCurrentUser: $e');
      rethrow;
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
    try {
      if (!await checkConnectivity()) {
        throw Exception('No internet connection');
      }

      final body = <String, dynamic>{};

      // إضافة البيانات فقط إذا كانت مش فاضية
      if (address != null && address.trim().isNotEmpty) {
        body['address'] = address.trim();
      }

      // إضافة كلمة المرور فقط إذا كان في تغيير
      if (currentPassword != null &&
          currentPassword.trim().isNotEmpty &&
          newPassword != null &&
          newPassword.trim().isNotEmpty) {
        body['current_password'] = currentPassword.trim();
        body['new_password'] = newPassword.trim();
      }

      // إذا مافيش حاجة للتحديث
      if (body.isEmpty) {
        print('⚠️ No data to update');
        return {'message': 'No changes made'};
      }

      print('📤 Update request body: $body');

      final response = await http
          .put(
            Uri.parse(ApiConstants.updateProfile),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('UpdateProfile Status: ${response.statusCode}');
      print('UpdateProfile Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 422) {
        // معالجة أخطاء التحقق
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Validation error';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            // إذا كان في multiple validation errors
            final errors = errorData['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              // أخذ أول خطأ
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else {
                errorMessage = firstError.toString();
              }
            }
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Invalid data provided');
        }
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        // Bad Request - غالباً مشكلة في البيانات
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Bad request';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Invalid request data');
        }
      } else {
        _handleError('updateProfile', response);
        throw Exception(
          'Failed to update profile. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error in updateProfile: $e');
      rethrow;
    }
  }

  // حذف الحساب
  static Future<bool> deleteAccount() async {
    try {
      if (!await checkConnectivity()) {
        throw Exception('No internet connection');
      }

      final response = await http
          .delete(
            Uri.parse(ApiConstants.deleteAccount),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('DeleteAccount Status: ${response.statusCode}');
      print('DeleteAccount Response: ${response.body}');

      if (response.statusCode == 200) {
        await clearToken();
        return true;
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired. Please login again.');
      } else {
        _handleError('deleteAccount', response);
        return false;
      }
    } catch (e) {
      print('💥 Error in deleteAccount: $e');
      return false;
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    await clearToken();
    print('✅ User logged out successfully');
  }

  // معالجة الأخطاء
  static void _handleError(String operation, http.Response response) {
    print('⚠️ $operation failed with status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 401) {
      clearToken();
    }
  }
}
