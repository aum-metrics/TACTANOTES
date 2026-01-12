import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../bridge_generated.dart/api.dart' as api;

class EngineProvider extends ChangeNotifier {
  bool _isRecording = false;
  String _currentTranscript = "";
  String _lastSummary = "";

  Timer? _mockTimer;

  bool get isRecording => _isRecording;
  String get currentTranscript => _currentTranscript;
  String get lastSummary => _lastSummary;

  // Folders & Notes
  List<(int, String)> _folders = [];
  List<(int, String, String, int)> _notes = []; // id, title, content, updated
  int? _currentFolderId;

  List<(int, String)> get folders => _folders;
  List<(int, String, String, int)> get notes => _notes;
  int? get currentFolderId => _currentFolderId;

  Future<void> loadFolders() async {
    try {
      if (!kIsWeb) {
         final dynamic result = await api.getFolders(); // Call directly
         _folders = (result as List).map< (int, String) >((e) {
            // Handle Tuple (BigInt/int, String)
            final id = e.$1 is BigInt ? (e.$1 as BigInt).toInt() : e.$1 as int;
            final name = e.$2 as String;
            return (id, name);
         }).toList();
      } else {
         // Web Mock: Return local in-memory folders
         // If empty, maybe add a default one?
         if (_folders.isEmpty) {
            _folders = [(1, "General (Web)")];
         }
      }
      notifyListeners();
    } catch (e) {
      print("Error loading folders: $e");
    }
  }

  Future<int?> createFolder(String name) async {
    try {
      int? newId;
      if (!kIsWeb) {
        final dynamic result = await api.createFolder(name: name);
        if (result is BigInt) newId = result.toInt();
        else if (result is int) newId = result;
      } else {
        // Web Mock: Add to local list
        newId = _folders.isEmpty ? 1 : _folders.last.$1 + 1;
        _folders.add((newId, name));
      }
      await loadFolders(); // Refresh
      return newId;
    } catch (e) {
       print("Error creating folder: $e");
       return null;
    }
  }

  Future<void> selectFolder(int? folderId) async {
    _currentFolderId = folderId;
    notifyListeners();
    try {
      if (!kIsWeb) {
         dynamic idToSend = folderId;
         if (kIsWeb && folderId != null) {
            idToSend = BigInt.from(folderId);
         }
         // Use dynamic dispatch to avoid static type error on Web build
         await api.setCurrentFolder(folderId: idToSend);
      }
      
      if (folderId != null) {
        await loadNotes(folderId);
      } else {
        _notes = [];
        notifyListeners();
      }
    } catch (e) {
      print("Error selecting folder: $e");
    }
  }

  Future<void> loadNotes(int folderId) async {
     try {
       if (!kIsWeb) {
         dynamic idToSend = folderId;
         if (kIsWeb) idToSend = BigInt.from(folderId);
         
         final dynamic result = await api.getNotesByFolder(folderId: idToSend);
         _notes = (result as List).map< (int, String, String, int) >((e) {
             final id = e.$1 is BigInt ? (e.$1 as BigInt).toInt() : e.$1 as int;
             final title = e.$2 as String;
             final content = e.$3 as String;
             final date = e.$4 is BigInt ? (e.$4 as BigInt).toInt() : e.$4 as int;
             return (id, title, content, date);
         }).toList();
       } else {
         // Web Mock: Return empty or sample notes for now
         if (_notes.isEmpty && folderId == 1) { // Only for General
             // _notes = [(101, "Sample Note", "This is a sample note on Web.", 1670000000)];
         }
         // In a real mock we would filter a master list by folderId
       }
       notifyListeners();
     } catch (e) {
       print("Error loading notes: $e");
     }
  }

  Future<void> startRecording(String subject) async {
    _isRecording = true;
    _currentTranscript = "Recording started... (Simulating)";
    notifyListeners();
    
    try {
      if (kIsWeb) {
        print("Web Mock: Recording Started");
        // Simulate streaming text
        int counter = 0;
        _mockTimer?.cancel();
        _mockTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
           counter++;
           // A fake stream of words
           final words = ["The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog", "Physics", "is", "cool"];
           final word = words[counter % words.length];
           _currentTranscript += " $word";
           notifyListeners();
           // print("Simulated token: $word"); // Debug
        });
      } else {
        // Call Real Rust Backend
        await api.startRecording(subject: subject);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> stop() async {
    _isRecording = false;
    _mockTimer?.cancel();
    notifyListeners();
    
    try {
      if (kIsWeb) {
        // Mock Web Behavior
        await Future.delayed(const Duration(seconds: 1));
        _lastSummary = "This is a simulated summary running on the Web because WASM compilation of the Heavy AI Core is skipped for this demo. The Native app runs the full local LLM.";
      } else {
        // Call Real Rust Backend which now returns the summary
        _lastSummary = await api.stopRecording();
        
        // Refresh notes in current folder if applicable
        if (_currentFolderId != null) {
           await loadNotes(_currentFolderId!);
        }
      }
      _currentTranscript = "Recording stopped. Summary generated.";
      notifyListeners();
    } catch (e) {
      print("Error stopping: $e");
    }
  }
}
