// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool isLocked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isLocked = widget.device["locked"] as bool;

    // تهيئة الرسوم المتحركة
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleLock() {
    setState(() {
      isLocked = !isLocked;
      widget.device["locked"] = isLocked;
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore:
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, isLocked);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            widget.device["name"],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة القفل مع رسوم متحركة
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder:
                      (context, child) => Transform.scale(
                        scale: 1.0 + _scaleAnimation.value * 0.1,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isLocked
                                        ? Colors.redAccent.withValues(alpha: 0.3)
                                        : Colors.greenAccent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isLocked ? Icons.lock : Icons.lock_open,
                            key: ValueKey<bool>(isLocked),
                            size: 120,
                            color:
                                isLocked
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                          ),
                        ),
                      ),
                ),

                const SizedBox(height: 30),

                // نص الحالة
                Text(
                  isLocked ? "Device is Locked 🔒" : "Device is Unlocked 🔓",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // نص وصفي إضافي
                Text(
                  isLocked
                      ? "Tap to unlock your device"
                      : "Tap to lock your device",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 60),

                // زر التحكم
                GestureDetector(
                  onTap: toggleLock,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: LinearGradient(
                        colors:
                            isLocked
                                ? [
                                  Colors.greenAccent,
                                  Colors.greenAccent.shade700,
                                ]
                                : [Colors.redAccent, Colors.redAccent.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isLocked
                                  ? Colors.greenAccent.withValues(alpha: 0.4)
                                  : Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isLocked ? "Unlock Device" : "Lock Device",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
