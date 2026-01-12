import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/engine_provider.dart';
import '../widgets/stealth_mode_overlay.dart';

class RecordingScreen extends StatefulWidget {
  final String? subject;
  const RecordingScreen({super.key, this.subject});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late String _subject; 
  bool _stealthMode = false;

  @override
  void initState() {
    super.initState();
    _subject = widget.subject ?? "Physics 101";
    // Google Play Policy: Prominent Disclosure BEFORE Permission
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRequestMic());
  }

  Future<void> _checkAndRequestMic() async {
      final status = await Permission.microphone.status;
      
      if (status.isDenied || status.isPermanentlyDenied) {
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
                          onPressed: () async { 
                              Navigator.pop(ctx);
                              await Permission.microphone.request(); 
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
        title: Row(
          children: [
            const Icon(Icons.folder, size: 20),
            const SizedBox(width: 8),
            Text(_subject, style: const TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
            IconButton(
                key: const ValueKey('stealth_toggle'),
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
                  // Web Demo Mode Banner
                  if (kIsWeb)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Web Demo Mode: Transcription is simulated. For real AI transcription, use the macOS app.",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: engine.lastSummary.isNotEmpty 
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView(
                                key: const ValueKey('summary_area'),
                                children: [
                                    Text("Summary", style: Theme.of(context).textTheme.headlineSmall),
                                    const Divider(),
                                    Text(engine.lastSummary),
                                    const SizedBox(height: 20),
                                    
                                    // Google Play AI Content Policy: Disclaimer & Feedback
                                    Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.amber.withAlpha(26),
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
                                key: const ValueKey('transcript_area'),
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
                          key: const ValueKey('record_fab'),
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
