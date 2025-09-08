import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_constants.dart';
import 'token_manager.dart';

class AuthService {
  final Dio _dio = Dio();

  /// الحصول على التوكن من SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// مسح التوكن (تسجيل خروج)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  /// تسجيل الدخول
  Future<Map<String, dynamic>> signin(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.signin,
        data: {"email": email, "password": password},
      );

      print("Signin Status: ${response.statusCode}");
      print("Response: ${response.data}");

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        // حفظ التوكنات باستخدام TokenManager
        await TokenManager.saveTokens(
          accessToken: response.data['access_token'],
          refreshToken: response.data['refresh_token'], // لو بيرجعه
        );

        return {
          "success": true,
          "message": "Login successful",
          "token": response.data['access_token'],
        };
      } else {
        return {
          "success": false,
          "message": response.data['message'] ?? "Login failed",
        };
      }
    } catch (e) {
      print("❌ Signin error: $e");
      return {"success": false, "message": "Login failed: ${e.toString()}"};
    }
  }

  /// تسجيل مستخدم جديد
  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.signup, data: data);

      print("Signup Status: ${response.statusCode}");
      print("Response: ${response.data}");

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": response.data['message'] ?? "Registration successful",
        };
      } else {
        return {
          "success": false,
          "message": response.data['message'] ?? "Registration failed",
        };
      }
    } catch (e) {
      print("❌ Signup error: $e");
      return {
        "success": false,
        "message": "Registration failed: ${e.toString()}",
      };
    }
  }

  /// 1. Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'identifier': identifier},
      );

      print("ForgotPassword Status: ${response.statusCode}");
      print("Response: ${response.data}");

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": response.data['message'] ?? "OTP sent successfully",
          "user_id": response.data['user_id'],
        };
      } else {
        return {
          "success": false,
          "message": response.data['message'] ?? "Failed, please try again",
        };
      }
    } catch (e) {
      print("❌ ForgotPassword error: $e");
      return {
        "success": false,
        "message": "Failed to send OTP: ${e.toString()}",
      };
    }
  }

  /// 2. Verify Reset OTP
  Future<Map<String, dynamic>> verifyResetOtp(int userId, String otp) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyResetOtp,
        data: {'user_id': userId, 'otp': otp},
      );

      print("VerifyResetOtp Status: ${response.statusCode}");
      print("Response: ${response.data}");

      if (response.statusCode == 200) {
        return {
          "success": true,
          "reset_token": response.data['reset_token'],
          "message": response.data['message'] ?? "OTP verified successfully",
        };
      } else {
        return {
          "success": false,
          "message": response.data['message'] ?? "OTP verification failed",
        };
      }
    } catch (e) {
      print("❌ VerifyResetOtp error: $e");
      return {
        "success": false,
        "message": "OTP verification failed: ${e.toString()}",
      };
    }
  }

  /// 3. Reset Password
  Future<Map<String, dynamic>> resetPassword(
    String newPassword,
    String resetToken,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {'new_password': newPassword, 'reset_token': resetToken},
      );

      print("ResetPassword Status: ${response.statusCode}");
      print("Response: ${response.data}");

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": response.data['message'] ?? "Password reset successfully",
        };
      } else {
        return {
          "success": false,
          "message": response.data['message'] ?? "Password reset failed",
        };
      }
    } catch (e) {
      print("❌ ResetPassword error: $e");
      return {
        "success": false,
        "message": "Password reset failed: ${e.toString()}",
      };
    }
  }
}
