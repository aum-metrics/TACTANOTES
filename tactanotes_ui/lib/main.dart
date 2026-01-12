import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/engine_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EngineProvider()),
      ],
      child: MaterialApp(
        title: 'TactaNotes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          // F15: Fonts & Readability
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark().copyWith(
          // F12: Dark Mode
        ),
        themeMode: ThemeMode.system, // F12: System Theme
        home: const LoginAuthWrapper(),
      ),
    );
  }
}

class LoginAuthWrapper extends StatefulWidget {
  const LoginAuthWrapper({super.key});

  @override
  State<LoginAuthWrapper> createState() => _LoginAuthWrapperState();
}

class _LoginAuthWrapperState extends State<LoginAuthWrapper> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // F14: Mandatory Login Once
    // In real app, check SharedPreferences or SecureStorage
    await Future.delayed(const Duration(milliseconds: 500)); // Sim check
    setState(() {
      _loggedIn = false; // Force login for demo
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
