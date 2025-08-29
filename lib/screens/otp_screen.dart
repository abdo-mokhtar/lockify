import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockify/screens/res.dart' show ResetPasswordScreen;
import 'dart:convert';
import '../api_constants.dart' show ApiConstants;
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final int userId;
  final bool isResetPassword;

  const OtpScreen({
    super.key,
    required this.userId,
    required this.isResetPassword,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack("Enter OTP", Colors.red);
      return;
    }

    if (otp.length != 6) {
      _showSnack("OTP must be exactly 6 digits", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint =
          widget.isResetPassword
              ? ApiConstants.verifyResetOtp
              : ApiConstants.verifyOtp;

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": widget.userId, "otp": otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnack("✅ OTP Verified", Colors.green);

        if (widget.isResetPassword) {
          final dynamic resetToken = responseData['reset_token'];
          if (resetToken is String) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ResetPasswordScreen(resetToken: resetToken),
              ),
            );
          } else {
            _showSnack("❌ Error: Missing reset token", Colors.red);
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        String errorMessage = '❌ Invalid OTP';
        final dynamic detail = responseData['detail'];

        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          errorMessage = detail[0]['msg'] ?? errorMessage;
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }

        _showSnack(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 100 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            hintText: "Enter 6-digit OTP",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blueAccent, Colors.cyan],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          "Verify",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
