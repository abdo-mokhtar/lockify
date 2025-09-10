import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';
import 'dart:async';

class OtpResetScreen extends StatefulWidget {
  final int userId;
  final String? identifier;

  const OtpResetScreen({super.key, required this.userId, this.identifier});

  @override
  State<OtpResetScreen> createState() => _OtpResetScreenState();
}

class _OtpResetScreenState extends State<OtpResetScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
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

  void _showCustomSnackBar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      duration: Duration(seconds: isSuccess ? 2 : 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpCode();

    if (otp.length != 6) {
      _showCustomSnackBar("Please enter complete 6-digit code", false);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.verifyResetOtp(widget.userId, otp);

      if (mounted) {
        setState(() => _loading = false);

        if (result['success']) {
          _showCustomSnackBar(result['message'], true);
          HapticFeedback.lightImpact();

          await Future.delayed(const Duration(milliseconds: 800));

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      ResetPasswordScreen(resetToken: result['reset_token']),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        } else {
          _showCustomSnackBar(result['message'], false);
          _clearOtpFields();
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showCustomSnackBar("Something went wrong. Try again.", false);
        _clearOtpFields();
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _loading) return;

    setState(() => _loading = true);

    try {
      final result = await _authService.forgotPassword(widget.identifier ?? "");

      if (mounted) {
        setState(() => _loading = false);

        if (result['success']) {
          _showCustomSnackBar("New verification code sent! 📲", true);
          _startResendTimer();
          _clearOtpFields();
        } else {
          _showCustomSnackBar(
            result['message'] ?? "Failed to resend code",
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showCustomSnackBar("Failed to resend code", false);
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
    // Calculate input field size to fit 6 fields with spacing
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
                      "Verify Reset Code",
                      style: TextStyle(
                        fontSize: 28 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Subtitle with identifier
                    Text(
                      widget.identifier != null
                          ? "Enter the 6-digit code sent to\n${widget.identifier}"
                          : "Enter the 6-digit verification code\nsent to your device",
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
                                    enabled: !_loading,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: TextStyle(
                                      color:
                                          Colors.white, // Brighter text color
                                      fontSize: 28 * fontScale, // Larger font
                                      fontWeight:
                                          FontWeight.w900, // Bolder text
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: "",
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 
                                        0.3,
                                      ), // Darker background
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ), // Center text vertically
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 
                                            0.5,
                                          ), // Visible border
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
                                    (_loading || _getOtpCode().length != 6)
                                        ? null
                                        : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: _loading ? 0 : 3,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          _loading || _getOtpCode().length != 6
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
                                        _loading
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              "Verify Code",
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

                    // Resend Code Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              (_canResend && !_loading) ? _resendOtp : null,
                          child: Text(
                            _canResend
                                ? "Resend"
                                : "Resend in ${_resendTimer}s",
                            style: TextStyle(
                              color:
                                  _canResend && !_loading
                                      ? Colors.blueAccent
                                      : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * fontScale,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.015),

                    // Back Button
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          color: _loading ? Colors.white38 : Colors.white70,
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
