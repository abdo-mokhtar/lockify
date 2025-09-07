import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class MonitoringService {
  // 1. Health Check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse(ApiConstants.healthCheck));

    print("HealthCheck Status: ${response.statusCode}");
    print("Response: ${response.body}");

    try {
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      return {
        "success": false,
        "message": "Invalid response: ${response.body}",
      };
    }
  }

  // 2. Readiness Check
  Future<Map<String, dynamic>> readinessCheck() async {
    final response = await http.get(Uri.parse(ApiConstants.readinessCheck));

    print("ReadinessCheck Status: ${response.statusCode}");
    print("Response: ${response.body}");

    try {
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      return {
        "success": false,
        "message": "Invalid response: ${response.body}",
      };
    }
  }

  // 3. Liveness Check
  Future<Map<String, dynamic>> livenessCheck() async {
    final response = await http.get(Uri.parse(ApiConstants.livenessCheck));

    print("LivenessCheck Status: ${response.statusCode}");
    print("Response: ${response.body}");

    try {
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      return {
        "success": false,
        "message": "Invalid response: ${response.body}",
      };
    }
  }
}
