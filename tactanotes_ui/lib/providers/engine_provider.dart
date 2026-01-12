import 'package:flutter/material.dart';
import '../bridge_definitions.dart';

class EngineProvider extends ChangeNotifier {
  bool _isRecording = false;
  String _currentTranscript = "";
  String _lastSummary = "";

  bool get isRecording => _isRecording;
  String get currentTranscript => _currentTranscript;
  String get lastSummary => _lastSummary;

  Future<void> startRecording(String subject) async {
    _isRecording = true;
    _currentTranscript = "";
    notifyListeners();
    
    await RustBridge.startRecording(subject);
    
    // Listen to stream
    // Listen to stream - F1: Memory Efficient Accumulation
    // Using StringBuffer to prevent O(N^2) string copying on every token.
    StringBuffer buffer = StringBuffer();
    
    RustBridge.transcriptionStream().listen((text) {
      if (text.isNotEmpty) {
          buffer.write(" $text");
          // Only notify UI occasionally or purely rely on local buffer if architecture permitted StreamBuilder
          // For now, we update the view state without string clone abuse
          _currentTranscript = buffer.toString(); 
          notifyListeners();
      }
    });
  }

  Future<void> stop() async {
    _isRecording = false;
    notifyListeners();
    
    _lastSummary = await RustBridge.stopAndSummarize();
    notifyListeners();
  }
}
