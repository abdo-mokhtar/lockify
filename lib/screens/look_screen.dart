import 'package:flutter/material.dart';
import 'package:lockify/screens/user_profile_screen%20.dart'
    show UserProfileScreen;
import 'device_detail_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<Map<String, dynamic>> devices = [
    {"name": "Front Door", "locked": true},
    {"name": "Garage", "locked": false},
    {"name": "Living Room", "locked": true},
  ];

  void toggleLock(int index) {
    setState(() {
      devices[index]["locked"] = !devices[index]["locked"];
    });
  }

  @override
  Widget build(BuildContext context) {
    // نحسب الأقفال
    int lockedCount = devices.where((d) => d["locked"]).length;
    int unlockedCount = devices.length - lockedCount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Smart Locks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // ✅ ملخص الأقفال
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummary("Locked", lockedCount, Colors.redAccent),
                    _buildSummary(
                      "Unlocked",
                      unlockedCount,
                      Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ القائمة
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isLocked = device["locked"] as bool;

                  return GestureDetector(
                    onTap: () async {
                      // افتح شاشة التفاصيل واستقبل الحالة الجديدة
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceDetailScreen(device: device),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          devices[index]["locked"] = result;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isLocked
                                  ? [
                                    const Color(0xFF283E51),
                                    const Color(0xFF485563),
                                  ]
                                  : [
                                    const Color(0xFF1D976C),
                                    const Color(0xFF93F9B9),
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // device name + state
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device["name"],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isLocked ? "Locked 🔒" : "Unlocked 🔓",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          // lock button
                          GestureDetector(
                            onTap: () => toggleLock(index),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder:
                                  (child, anim) => RotationTransition(
                                    turns: anim,
                                    child: child,
                                  ),
                              child: Icon(
                                isLocked ? Icons.lock : Icons.lock_open,
                                key: ValueKey<bool>(isLocked),
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت صغيرة للملخص
  Widget _buildSummary(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }
}
