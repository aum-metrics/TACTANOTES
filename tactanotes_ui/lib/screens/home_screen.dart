import 'package:flutter/material.dart'; // Add this back if needed for colors/icons
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/engine_provider.dart';
import '../widgets/folder_sidebar.dart';
import 'recording_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch provider
    final engine = context.watch<EngineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("TactaNotes"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          const FolderSidebar(),
          const VerticalDivider(width: 1),
          // Content
          Expanded(
            child: engine.currentFolderId == null
                ? const Center(child: Text("Select a folder to view notes"))
                : ListView.builder(
                    itemCount: engine.notes.length,
                    itemBuilder: (context, index) {
                      final note = engine.notes[index];
                      // Note tuple: (id, title, content, updated)
                      final title = note.$2;
                      final content = note.$3;
                      final updated = DateTime.fromMillisecondsSinceEpoch(note.$4 * 1000);
                      
                      return ListTile(
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          content.split('\n').first, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        trailing: Text("${updated.month}/${updated.day}"),
                        onTap: () {
                          // TODO: Open Note Editor
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: engine.currentFolderId != null ? FloatingActionButton(
        key: const ValueKey('record_button'),
        onPressed: () {
          // Pass current folder name as subject for now
          final folderName = engine.folders.firstWhere((f) => f.$1 == engine.currentFolderId).$2;
          Navigator.push(context, MaterialPageRoute(builder: (_) => RecordingScreen(subject: folderName)));
        },
        child: const Icon(Icons.mic),
      ) : null,
    );
  }
}
