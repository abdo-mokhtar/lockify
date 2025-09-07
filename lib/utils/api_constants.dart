class ApiConstants {
  // غير الـ IP حسب جهازك
  static const String baseUrl = "http://192.168.1.185:8000/api/v1";

  // Auth
  static const String signup = "$baseUrl/auth/signup";
  static const String signin = "$baseUrl/auth/signin";
  static const String verifyOtp = "$baseUrl/auth/verify-otp";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String verifyResetOtp = "$baseUrl/auth/verify-reset-otp";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  // User Profile APIs
  static const String getCurrentUser = "$baseUrl/users/me";
  static const String updateProfile = "$baseUrl/users/me";
  static const String deleteAccount = "$baseUrl/users/me";

  // System Monitoring APIs
  static const String healthCheck = "$baseUrl/health";
  static const String readinessCheck = "$baseUrl/health/ready";
  static const String livenessCheck = "$baseUrl/health/live";
}
