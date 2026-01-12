import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tactanotes_ui/providers/engine_provider.dart';
import 'package:tactanotes_ui/screens/recording_screen.dart';
import 'package:tactanotes_ui/widgets/stealth_mode_overlay.dart';

// E2E UI Test: Verifying Stealth Mode Integration
void main() {
  testWidgets('Stealth Mode Overlay appears when toggled', (WidgetTester tester) async {
    // 1. Pump the RecordingScreen with Provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EngineProvider()),
        ],
        child: const MaterialApp(home: RecordingScreen()),
      ),
    );

    // Handle the permission dialog
    await tester.pumpAndSettle(); // Wait for dialog to appear
    expect(find.text("Microphone Access Needed"), findsOneWidget);
    await tester.tap(find.text("Continue"));
    await tester.pumpAndSettle(); // Dismiss dialog

    // 2. Verify initial state (Stealth mode OFF)
    expect(find.byType(StealthModeOverlay), findsNothing);
    expect(find.byIcon(Icons.battery_saver), findsOneWidget);

    // 3. Tap the Battery Saver icon
    await tester.tap(find.byIcon(Icons.battery_saver));
    await tester.pump(); // Rebuild the widget

    // 4. Verify Stealth Mode is ON (Overlay present)
    expect(find.byType(StealthModeOverlay), findsOneWidget);
    expect(find.textContaining("REC"), findsOneWidget); // Heartbeat text

    // Note: Double tap to dismiss is tested separately or manually
  });
}
