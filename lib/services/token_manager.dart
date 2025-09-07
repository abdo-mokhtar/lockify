import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static String? _cachedToken;
  static String? _cachedRefreshToken;
  static Timer? _refreshTimer;

  // حفظ التوكن مع تحديد وقت انتهاء الصلاحية
  static Future<bool> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // حفظ الـ access token
      await prefs.setString(_tokenKey, accessToken);
      _cachedToken = accessToken;

      // حفظ الـ refresh token إذا موجود
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
        _cachedRefreshToken = refreshToken;
      }

      // استخراج وحفظ وقت انتهاء الصلاحية من JWT
      final expiry = _extractExpiryFromToken(accessToken);
      if (expiry != null) {
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
        _scheduleTokenRefresh(expiry);
      }

      print('✅ Tokens saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving tokens: $e');
      return false;
    }
  }

  // جلب التوكن مع فحص انتهاء الصلاحية
  static Future<String?> getValidToken() async {
    // التحقق من الـ cache أولاً
    if (_cachedToken != null && await _isTokenValid(_cachedToken!)) {
      return _cachedToken;
    }

    // جلب من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      print('❌ No token found');
      return null;
    }

    // فحص صحة التوكن
    if (await _isTokenValid(token)) {
      _cachedToken = token;
      return token;
    }

    // محاولة تحديث التوكن إذا كان منتهي الصلاحية
    print('🔄 Token expired, attempting refresh...');
    return await _refreshToken();
  }

  // فحص صحة التوكن
  static Future<bool> _isTokenValid(String token) async {
    try {
      final expiry = _extractExpiryFromToken(token);
      if (expiry == null) return true; // إذا مش قادر أحدد، هفترض صحيح

      final now = DateTime.now();
      final bufferTime = const Duration(minutes: 5); // buffer 5 دقايق

      final isValid = now.isBefore(expiry.subtract(bufferTime));
      print('⏰ Token expiry: $expiry, Valid: $isValid');

      return isValid;
    } catch (e) {
      print('⚠️ Error checking token validity: $e');
      return false;
    }
  }

  // استخراج وقت انتهاء الصلاحية من JWT
  static DateTime? _extractExpiryFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);

      final exp = data['exp'];
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      print('⚠️ Error extracting token expiry: $e');
      return null;
    }
  }

  // تحديث التوكن باستخدام refresh token
  static Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) {
        print('❌ No refresh token available');
        await clearTokens();
        return null;
      }

      // استدعاء API لتحديث التوكن
      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/auth/refresh',
            ), // غير الـ URL حسب API بتاعك
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? refreshToken;

        await saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        print('✅ Token refreshed successfully');
        return newAccessToken;
      } else {
        print('❌ Token refresh failed: ${response.statusCode}');
        await clearTokens();
        return null;
      }
    } catch (e) {
      print('💥 Error refreshing token: $e');
      await clearTokens();
      return null;
    }
  }

  // جدولة تحديث التوكن تلقائياً
  static void _scheduleTokenRefresh(DateTime expiry) {
    _refreshTimer?.cancel();

    final now = DateTime.now();
    final refreshTime = expiry.subtract(
      const Duration(minutes: 10),
    ); // تحديث قبل 10 دقايق من الانتهاء

    if (refreshTime.isAfter(now)) {
      final duration = refreshTime.difference(now);
      print('⏱️ Token refresh scheduled in: ${duration.inMinutes} minutes');

      _refreshTimer = Timer(duration, () async {
        print('🔄 Auto refreshing token...');
        await _refreshToken();
      });
    }
  }

  // مسح كل التوكنات
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);

      _cachedToken = null;
      _cachedRefreshToken = null;
      _refreshTimer?.cancel();

      print('🗑️ All tokens cleared');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  // فحص إذا كان المستخدم مسجل دخول
  static Future<bool> isLoggedIn() async {
    final token = await getValidToken();
    return token != null;
  }

  // إضافة listener لتنبيه عند انتهاء الصلاحية
  static final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  static Stream<bool> get authStateStream => _authStateController.stream;

  static void _notifyAuthStateChange(bool isAuthenticated) {
    if (!_authStateController.isClosed) {
      _authStateController.add(isAuthenticated);
    }
  }

  // تنظيف الموارد
  static void dispose() {
    _refreshTimer?.cancel();
    _authStateController.close();
  }
}
