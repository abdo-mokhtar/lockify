import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late bool isLocked;

  @override
  void initState() {
    super.initState();
    isLocked = widget.device["locked"] as bool;
  }

  void toggleLock() {
    setState(() {
      isLocked = !isLocked;
      widget.device["locked"] = isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ علشان نرجع الحالة مع الرجوع
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
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true, // ✅ يخلي زرار الرجوع يظهر
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة القفل
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder:
                    (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  key: ValueKey<bool>(isLocked),
                  size: 150,
                  color: isLocked ? Colors.redAccent : Colors.greenAccent,
                ),
              ),

              const SizedBox(height: 20),

              // الحالة
              Text(
                isLocked ? "Device is Locked 🔒" : "Device is Unlocked 🔓",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 50),

              // زرار التحكم
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLocked ? Colors.greenAccent : Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                onPressed: toggleLock,
                child: Text(
                  isLocked ? "Unlock Now" : "Lock Now",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
