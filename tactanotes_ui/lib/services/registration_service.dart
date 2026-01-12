import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http; // For real impl

class RegistrationService {
  static const String KEY_IS_REGISTERED = "is_registered";

  /// 1. Check if device is already registered
  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_REGISTERED) ?? false;
  }

  /// 2. Perform the "One-Shot" Registration
  /// Sends {name, email, country, device_id} to the Central Registry
  Future<bool> registerUser(String name, String email, String country) async {
    try {
      // Mock Network Delay
      await Future.delayed(const Duration(seconds: 2));

      // --- REAL IMPLEMENTATION PATTERN ---
      /*
      final response = await http.post(
          Uri.parse("https://api.tactanotes.com/v1/register"),
          body: {
              "name": name,
              "email": email,
              "country": country,
              "device_id": Platform.operatingSystem,
              "timestamp": DateTime.now().toIso8601String()
          }
      );
      if (response.statusCode != 200) throw Exception("Server Error");
      */
      // -----------------------------------

      if (email.contains("fail")) throw Exception("Invalid Email"); // Mock error

      // Mark as Registered locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KEY_IS_REGISTERED, true);
      await prefs.setString("user_name", name); // For "Hello, Name" UI
      
      if (kDebugMode) {
        print("Registry: Success! User '$email' logged in central DB.");
      }
      return true;
      
    } catch (e) {
      print("Registry Error: $e");
      return false;
    }
  }
}
