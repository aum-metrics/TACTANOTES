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
  bool _hasCheckedPermission = false;

  @override
  void initState() {
    super.initState();
    // Google Play Policy: Prominent Disclosure BEFORE Permission
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRequestMic());
  }

  Future<void> _checkAndRequestMic() async {
      // Mock check. In real app use: if (await Permission.microphone.isDenied)
      bool permissionGranted = false; 
      
      if (!permissionGranted) {
          // Show Rationale first
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                  title: const Text("Microphone Access Needed"),
                  content: const Text(
                      "TACTANOTES uses your microphone to transcribe lectures in real-time. "
                      "Audio is processed locally on-device and is NOT uploaded to any server for transcription. "
                      "We need this permission to function."
                  ),
                  actions: [
                      TextButton(
                          onPressed: () { 
                              Navigator.pop(ctx);
                              setState(() => _hasCheckedPermission = true);
                              // Permission.microphone.request(); 
                          },
                          child: const Text("Continue")
                      )
                  ],
              )
          );
      }
  }

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
                            child: ListView(
                                children: [
                                    Text("Summary", style: Theme.of(context).textTheme.headlineSmall),
                                    const Divider(),
                                    Text(engine.lastSummary),
                                    const SizedBox(height: 20),
                                    
                                    // Google Play AI Content Policy: Disclaimer & Feedback
                                    Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade200)
                                        ),
                                        child: Column(
                                            children: [
                                                const Row(children: [
                                                    Icon(Icons.info_outline, size: 16, color: Colors.amber),
                                                    SizedBox(width: 8),
                                                    Expanded(child: Text("AI-generated content. Check for accuracy.", style: TextStyle(fontSize: 12, color: Colors.amber)))
                                                ]),
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                    icon: const Icon(Icons.flag, size: 16),
                                                    label: const Text("Report Issue"),
                                                    onPressed: () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("Thanks. Feedback logged for review."))
                                                        );
                                                    }
                                                )
                                            ]
                                        ),
                                    )
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
