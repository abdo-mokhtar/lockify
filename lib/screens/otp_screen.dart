import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart' show ApiConstants;
import 'login_screen.dart';
import 'reset_password_screen.dart';

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
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpCode();

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
        _clearOtpFields();
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
      _clearOtpFields();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > 600;

    // Dynamic sizing based on screen dimensions
    final double fontScale = MediaQuery.of(context).textScaler.scale(1);
    final double inputFieldSize =
        isWide
            ? 60.0
            : (screenWidth - 48 - 60) /
                6; // Subtract padding (24*2) and spacing (10*6)
    final double padding = isWide ? screenWidth * 0.15 : 24.0;
    final double iconSize = isWide ? 120.0 : screenHeight * 0.15;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600 : screenWidth * 0.9,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Icon with Animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.verified_user,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Title
                    Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 28 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Subtitle
                    Text(
                      "Enter the 6-digit code sent to your device",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // OTP Input Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 30 : 20),
                        child: Column(
                          children: [
                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: inputFieldSize,
                                  height: inputFieldSize * 1.3,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    enabled: !_isLoading,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28 * fontScale,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: "",
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.3),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color:
                                              _otpControllers[index]
                                                      .text
                                                      .isNotEmpty
                                                  ? Colors.green.withValues(alpha: 
                                                    0.7,
                                                  )
                                                  : Colors.white.withValues(alpha: 
                                                    0.5,
                                                  ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 5) {
                                        _focusNodes[index + 1].requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _focusNodes[index - 1].requestFocus();
                                      }

                                      setState(() {});

                                      if (index == 5 && value.isNotEmpty) {
                                        final otpCode = _getOtpCode();
                                        if (otpCode.length == 6) {
                                          FocusScope.of(context).unfocus();
                                          _verifyOtp();
                                        }
                                      }
                                    },
                                    onTap: () {
                                      if (_otpControllers[index]
                                          .text
                                          .isNotEmpty) {
                                        _otpControllers[index]
                                            .selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _otpControllers[index]
                                                  .text
                                                  .length,
                                        );
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: screenHeight * 0.04),

                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: isWide ? 60 : 50,
                              child: ElevatedButton(
                                onPressed:
                                    (_isLoading || _getOtpCode().length != 6)
                                        ? null
                                        : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: _isLoading ? 0 : 3,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          _isLoading ||
                                                  _getOtpCode().length != 6
                                              ? [
                                                Colors.grey,
                                                Colors.grey.shade600,
                                              ]
                                              : [
                                                Colors.blueAccent,
                                                Colors.cyan,
                                              ],
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
                                            : Text(
                                              "Verify",
                                              style: TextStyle(
                                                fontSize: 18 * fontScale,
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

                    SizedBox(height: screenHeight * 0.03),

                    // Back Button
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          color: _isLoading ? Colors.white38 : Colors.white70,
                          decoration: TextDecoration.underline,
                          fontSize: 16 * fontScale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
