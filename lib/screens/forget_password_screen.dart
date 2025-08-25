import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _phoneController = TextEditingController();

    void _resetPassword() {
      if (_emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📩 Reset link has been sent to your email"),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Please fill all fields")),
        );
      }
    }

    // Custom TextField حديثة
    Widget _buildCustomTextField({
      required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF5563DE)),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF5563DE), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 15,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74ABE2), Color(0xFF5563DE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة القفل
                  const Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Color(0xFF5563DE),
                  ),
                  const SizedBox(height: 15),

                  // العنوان
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Enter your email and phone to reset your password",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 25),

                  // Email
                  _buildCustomTextField(
                    controller: _emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  _buildCustomTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 25),

                  // زر إرسال الرابط
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: const Color(0xFF5563DE),
                    ),
                    onPressed: _resetPassword,
                    child: const Text(
                      "Send Reset Link",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // زر العودة لتسجيل الدخول
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
