class ApiConstants {
  // غيّر الـ IP ده حسب جهازك
  static const String baseUrl = "http://192.168.1.185:8000/api/v1/auth";

  static const String signup = "$baseUrl/signup";
  static const String signin = "$baseUrl/signin";
  static const String verifyOtp = "$baseUrl/verify-otp";
  static const String forgotPassword = "$baseUrl/forgot-password";
  static const String verifyResetOtp = "$baseUrl/verify-reset-otp";
  static const String resetPassword = "$baseUrl/reset-password";
}
