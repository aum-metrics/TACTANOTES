import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../src/rust/api.dart' as api;
import '../src/rust/frb_generated.dart' show PlatformInt64;

class EngineProvider extends ChangeNotifier {
  bool _isRecording = false;
  String _currentTranscript = "";
  String _lastSummary = "";

  Timer? _mockTimer;

  bool get isRecording => _isRecording;
  String get currentTranscript => _currentTranscript;
  String get lastSummary => _lastSummary;

  String? _lastError;
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Folders & Notes
  List<(int, String)> _folders = [];
  Map<int, List<(int, String, String, int)>> _notesByFolder = {}; // folderId -> notes
  int? _currentFolderId;
  String _userName = "User"; // Add user name

  List<(int, String)> get folders => _folders;
  List<(int, String, String, int)> get notes => _notesByFolder[_currentFolderId] ?? [];
  Map<int, List<(int, String, String, int)>> get notesByFolder => _notesByFolder;
  int? get currentFolderId => _currentFolderId;
  String get userName => _userName;

  Future<void> loadFolders() async {
    try {
      if (!kIsWeb) {
         print("Dart: Loading folders from Rust...");
         final dynamic result = await api.getFolders();
         final List<(int, String)> loadedFolders = (result as List).map< (int, String) >((e) {
            // Robust type conversion for PlatformInt64
            int id;
            if (e.$1 is BigInt) id = (e.$1 as BigInt).toInt();
            else if (e.$1 is int) id = e.$1;
            else id = int.parse(e.$1.toString());
            
            final name = e.$2 as String;
            return (id, name);
         }).toList();
         
         _folders = loadedFolders;
         print("Dart: Loaded ${_folders.length} folders.");
         
         // Auto-select first folder if none selected and folders exist
         if (_currentFolderId == null && _folders.isNotEmpty) {
            print("Dart: Auto-selecting first folder: ${_folders.first.$2}");
            await selectFolder(_folders.first.$1);
         }
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
        newId = result is int ? result : (result as dynamic).toInt();
      } else {
        // Web Mock: Add to local list
        newId = _folders.isEmpty ? 1 : _folders.last.$1 + 1;
        _folders.add((newId, name));
      }
      await loadFolders(); // Refresh
      return newId;
    } catch (e) {
       _lastError = "Folder Error: $e";
       print("Dart Error: $_lastError");
       notifyListeners();
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
        // Clear current folder's notes
        if (_currentFolderId != null) {
          _notesByFolder[_currentFolderId!] = [];
        }
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
         final notes = (result as List).map< (int, String, String, int) >((e) {
             final id = e.$1 is int ? e.$1 : (e.$1 as dynamic).toInt();
             final title = e.$2 as String;
             final content = e.$3 as String;
             final date = e.$4 is int ? e.$4 : (e.$4 as dynamic).toInt();
             return (id, title, content, date);
         }).toList();
         _notesByFolder[folderId] = notes;
       } else {
         // Web Mock: Initialize folder's note list if not exists
         if (!_notesByFolder.containsKey(folderId)) {
           _notesByFolder[folderId] = [];
           print("Web Mock: Initialized empty note list for folder $folderId");
         }
         print("Web Mock: Loaded ${_notesByFolder[folderId]!.length} notes for folder $folderId");
       }
       notifyListeners();
     } catch (e) {
       _lastError = "Notes Error: $e";
       print("Dart Error: $_lastError");
       notifyListeners();
     }
  }

  Future<void> startRecording(String subject) async {
    _isRecording = true;
    _currentTranscript = "";
    notifyListeners();
    
    _mockTimer?.cancel();
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
        
        // Start Polling Timer (F01: Real-time Feedback)
        _mockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
          try {
            final transcript = await api.getCurrentTranscript();
            if (transcript != _currentTranscript) {
              _currentTranscript = transcript;
              notifyListeners();
            }
          } catch (e) {
            print("Error polling transcript: $e");
          }
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> stop({int? appendToNoteId}) async {
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
        _lastSummary = await api.stopRecording(appendTo: appendToNoteId);
        
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

  Future<List<(int, String, String)>> getAttachments(int noteId) async {
    try {
      if (kIsWeb) return [];
      final result = await api.getAttachments(noteId: noteId);
      return result.map((e) => (
        (e.$1 is int ? e.$1 : (e.$1 as dynamic).toInt()) as int,
        e.$2,
        e.$3
      )).toList();
    } catch (e) {
      print("Error fetching attachments: $e");
      return [];
    }
  }

  Future<int?> addAttachment(int noteId, String type, String path) async {
    try {
      if (kIsWeb) return null;
      final result = await api.addAttachment(noteId: noteId, fileType: type, filePath: path);
      return result is int ? result : (result as dynamic).toInt();
    } catch (e) {
      print("Error adding attachment: $e");
      return null;
    }
  }

  Future<bool> createNote(String title, String content) async {
    try {
      if (!kIsWeb) {
        // Call backend to create note in current folder
        if (_currentFolderId == null) {
          print("Error: No folder selected");
          return false;
        }
        
        dynamic folderIdToSend = _currentFolderId;
        if (kIsWeb && _currentFolderId != null) {
          folderIdToSend = BigInt.from(_currentFolderId!);
        }
        
        final dynamic result = await api.addNote(
          title: title, 
          content: content,
          folderId: folderIdToSend,
        );
        
        // Refresh notes list
        await loadNotes(_currentFolderId!);
        return true;
      } else {
        // Web Mock: Add to folder-specific list
        if (_currentFolderId == null) {
          print("Web Mock ERROR: Cannot create note - no folder selected!");
          return false;
        }
        
        // Ensure folder exists in map
        if (!_notesByFolder.containsKey(_currentFolderId)) {
          _notesByFolder[_currentFolderId!] = [];
        }
        
        final folderNotes = _notesByFolder[_currentFolderId!]!;
        final newId = folderNotes.isEmpty ? 1 : folderNotes.map((n) => n.$1).reduce((a, b) => a > b ? a : b) + 1;
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        folderNotes.insert(0, (newId, title, content, timestamp));
        print("Web Mock: Created note $newId in folder $_currentFolderId. Total notes: ${folderNotes.length}");
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error creating note: $e");
      return false;
    }
  }

  Future<bool> updateNote(int noteId, String title, String content) async {
    try {
      if (!kIsWeb) {
        dynamic idToSend = noteId;
        if (kIsWeb) idToSend = BigInt.from(noteId);
        
        await api.updateNote(
          noteId: idToSend,
          title: title,
          content: content,
        );
        
        // Refresh notes list
        if (_currentFolderId != null) {
          await loadNotes(_currentFolderId!);
        }
        return true;
      } else {
        // Web Mock: Update in folder-specific list
        if (_currentFolderId == null) return false;
        
        final folderNotes = _notesByFolder[_currentFolderId!] ?? [];
        final index = folderNotes.indexWhere((n) => n.$1 == noteId);
        if (index != -1) {
          final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          folderNotes[index] = (noteId, title, content, timestamp);
          print("Web Mock: Updated note $noteId in folder $_currentFolderId");
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print("Error updating note: $e");
      return false;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      if (!kIsWeb) {
        dynamic idToSend = noteId;
        if (kIsWeb) idToSend = BigInt.from(noteId);
        
        await api.deleteNote(noteId: idToSend);
        
        // Refresh notes list
        if (_currentFolderId != null) {
          await loadNotes(_currentFolderId!);
        }
        return true;
      } else {
        // Web Mock: Remove from folder-specific list
        if (_currentFolderId == null) return false;
        
        final folderNotes = _notesByFolder[_currentFolderId!] ?? [];
        folderNotes.removeWhere((n) => n.$1 == noteId);
        print("Web Mock: Deleted note $noteId from folder $_currentFolderId");
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error deleting note: $e");
      return false;
    }
  }

  Future<(int, String, String, int)?> getNote(int noteId) async {
    try {
      if (kIsWeb) {
        if (_currentFolderId == null) return null;
        final folderNotes = _notesByFolder[_currentFolderId!] ?? [];
        return folderNotes.firstWhere((n) => n.$1 == noteId);
      }
      final result = await api.getNote(noteId: noteId);
      return (
        (result.$1 is int ? result.$1 : (result.$1 as dynamic).toInt()) as int,
        result.$2,
        result.$3,
        (result.$4 is int ? result.$4 : (result.$4 as dynamic).toInt()) as int,
      );
    } catch (e) {
      print("Error fetching note $noteId: $e");
      return null;
    }
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  // Feature F16: Search UI Bridge
  Future<List<(int, String, String, int)>> searchNotes(String query) async {
    try {
      if (kIsWeb) return [];
      print("Dart: Searching for '$query'...");
      final result = await api.searchNotes(query: query);
      return result.map((e) => (
         (e.$1 is int ? e.$1 : (e.$1 as dynamic).toInt()) as int,
         e.$2,
         e.$3,
         (e.$4 is int ? e.$4 : (e.$4 as dynamic).toInt()) as int,
      )).toList();
    } catch (e) {
      print("Error searching notes: $e");
      return [];
    }
  }
}
