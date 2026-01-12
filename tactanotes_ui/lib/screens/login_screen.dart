import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/registration_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regService = RegistrationService();
  
  // State
  bool _isRegistering = false; // Default to Login, but check prefs
  bool _isLoading = false;
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _country = "India"; // Default

  @override
  void initState() {
      super.initState();
      _checkStatus();
  }

  Future<void> _checkStatus() async {
      // If already registered, show Login mode. If not, show Register mode.
      bool registered = await _regService.isRegistered();
      setState(() {
          _isRegistering = !registered;
      });
  }

  Future<void> _handleSubmit() async {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() => _isLoading = true);
      
      if (_isRegistering) {
          // 1. Cloud Registration
          bool success = await _regService.registerUser(
              _nameCtrl.text, 
              _emailCtrl.text, 
              _country
          );
          
          if (success) {
              // 2. Local Key Derivation (Mocked here for UI flow)
              if (mounted) {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              }
          } else {
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Failed. Try again.")));
          }
      } else {
          // Login Mode: Just Local Key Check
          await Future.delayed(const Duration(seconds: 1)); // Hardware crypto time
          if (mounted) {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          }
      }
      
      if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      const Icon(Icons.security, size: 64, color: Colors.black87),
                      const SizedBox(height: 16),
                      Text(_isRegistering ? "Create Profile" : "Welcome Back", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          _isRegistering ? "One-time registration for TACTANOTES" : "Enter password to decrypt your notes", 
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      if (_isRegistering) ...[
                          TextFormField(
                              key: const ValueKey('name_field'),
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                              key: const ValueKey('email_field'),
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder()),
                              validator: (v) => !v!.contains("@") ? "Invalid Email" : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                              initialValue: _country,
                              decoration: const InputDecoration(labelText: "Country", border: OutlineInputBorder()),
                              items: ["India", "USA", "UK", "Other"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _country = v!),
                          ),
                          const SizedBox(height: 16),
                      ],
        
                      TextFormField(
                          key: const ValueKey('password_field'),
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "Master Password", border: OutlineInputBorder()),
                          validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            key: const ValueKey('login_button'),
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_isRegistering ? "Register Device" : "Unlock Vault"),
                          ),
                      ),
                      
                      if (!_isRegistering)
                          TextButton(
                              onPressed: () { setState(() => _isRegistering = true); },
                              child: const Text("New Device? Register Here")
                          )
                    ],
                  ),
              ),
            ),
        ),
      ),
    );
  }
}
