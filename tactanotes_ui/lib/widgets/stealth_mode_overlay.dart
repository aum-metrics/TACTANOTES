import 'package:flutter/material.dart';
import 'dart:async';

// Feature v5.3: OLED Stealth Mode
// Turns screen black to save battery. Shows only faint heartbeat.

class StealthModeOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const StealthModeOverlay({super.key, required this.onDismiss});

  @override
  State<StealthModeOverlay> createState() => _StealthModeOverlayState();
}

class _StealthModeOverlayState extends State<StealthModeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  Timer? _timer;
  String _timeString = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.2, end: 0.6).animate(_controller);
    
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
  }
  
  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('stealth_overlay'),
      onDoubleTap: widget.onDismiss, // Double tap to wake
      child: Container(
        color: Colors.black, // OLED off
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: AnimatedBuilder(
            animation: _opacity,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      "REC  $_timeString",
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white54,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Double-tap to wake",
                      style: TextStyle(
                        color: Colors.white24, 
                        fontSize: 10,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
