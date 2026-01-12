import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/engine_provider.dart';
import '../widgets/stealth_mode_overlay.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  String _subject = "Physics 101"; // Default
  bool _stealthMode = false;
  
  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<EngineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _subject,
            items: ["Physics 101", "Calculus II"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _subject = v!),
          ),
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.battery_saver),
                tooltip: "Toggle Stealth Mode",
                onPressed: () => setState(() => _stealthMode = !_stealthMode),
            )
        ],
      ),
      body: Stack(
          children: [
              Column(
                children: [
                  Expanded(
                    child: engine.lastSummary.isNotEmpty 
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("Summary", style: Theme.of(context).textTheme.headlineSmall),
                                    const Divider(),
                                    Text(engine.lastSummary),
                                ]
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView( // F1: Streaming Transcript View
                                child: Text(
                                    engine.currentTranscript.isEmpty ? "Tap mic to start..." : engine.currentTranscript,
                                    style: const TextStyle(fontSize: 18, height: 1.5),
                                ),
                            ),
                          ),
                  ),
                  
                  // F4: Instant Switching UI (Tabs or Toggle - Simplified here)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.large(
                          backgroundColor: engine.isRecording ? Colors.red : Colors.blueAccent,
                          onPressed: () {
                            if (engine.isRecording) {
                              engine.stop();
                            } else {
                              engine.startRecording(_subject);
                            }
                          },
                          child: Icon(engine.isRecording ? Icons.stop : Icons.mic),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              
              if (_stealthMode) 
                 StealthModeOverlay(onDismiss: () => setState(() => _stealthMode = false)),
          ],
      ),
    );
  }
}
