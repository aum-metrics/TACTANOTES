import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // "Academic Calm" - minimal
            children: [
              const Text("TACTANOTES", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Offline-First AI Companion", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Simulate Login
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Sign In with Email"),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () {}, child: const Text("Continue as Guest (Limited)"))
            ],
          ),
        ),
      ),
    );
  }
}
