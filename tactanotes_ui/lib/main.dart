import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/engine_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'src/rust/frb_generated.dart'; // Import for RustLib.init()
import 'src/rust/api.dart' as api;

void main() async {
  try {
    if (!kIsWeb) {
      WidgetsFlutterBinding.ensureInitialized();
      await RustLib.init();
      
      final appSupportDir = await getApplicationSupportDirectory();
      final dbPath = "${appSupportDir.path}/tactanotes.db";
      
      // Resolve models directory
      // 1. Bundle path (macOS)
      String modelsDir = "${Platform.resolvedExecutable.replaceAll("/MacOS/tactanotes_ui", "")}/Resources/flutter_assets/assets/models";
      
      // 2. Fallback for Dev (Relative to project root)
      if (!Directory(modelsDir).existsSync()) {
        modelsDir = "${Directory.current.path}/assets/models";
      }
      
      // 3. Absolute Fallback (User's specific path if others fail)
      if (!Directory(modelsDir).existsSync()) {
        modelsDir = "/Users/sambath/Documents/CODE/coding/TACTANOTES/tactanotes_ui/assets/models";
      }

      print("Initializing Rust with DB path: $dbPath");
      print("Initializing Rust with Models dir: $modelsDir");
      await api.initApp(dbPath: dbPath, modelsDir: modelsDir);
    } else {
      print("Web Mock Mode: Skipping Rust Init");
    }
    runApp(const MyApp());
  } catch (e, stack) {
    print("Error initializing Rust: $e");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Text("Init Error: $e\n$stack", style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
  }
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
      _loggedIn = false; // Enable login flow
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? HomeScreen() : LoginScreen();
  }
}
