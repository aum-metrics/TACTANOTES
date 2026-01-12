import 'package:flutter/material.dart'; // Add this back if needed for colors/icons
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/engine_provider.dart';
import '../widgets/folder_sidebar.dart';
import 'recording_screen.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final engine = context.read<EngineProvider>();
      engine.addListener(() {
        if (engine.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(engine.lastError!),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: "Clear",
                textColor: Colors.white,
                onPressed: () => engine.clearError(),
              ),
            ),
          );
          // Auto-clear after showing? Better to let user clear or timeout
        }
      });
    });
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Notes"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Enter search term...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onChanged: (value) {
                  // Trigger rebuild to show results
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<EngineProvider>(
                  builder: (context, engine, _) {
                    final query = searchController.text.toLowerCase();
                    if (query.isEmpty) {
                      return const Center(child: Text("Type to search..."));
                    }
                    
                    // Search across all folders
                    final results = <(int, String, String, int, String)>[]; // noteId, title, content, timestamp, folderName
                    engine.folders.forEach((folder) {
                      final folderId = folder.$1;
                      final folderName = folder.$2;
                      final notes = engine.notesByFolder[folderId] ?? [];
                      
                      for (var note in notes) {
                        final title = note.$2.toLowerCase();
                        final content = note.$3.toLowerCase();
                        if (title.contains(query) || content.contains(query)) {
                          results.add((note.$1, note.$2, note.$3, note.$4, folderName));
                        }
                      }
                    });
                    
                    if (results.isEmpty) {
                      return const Center(child: Text("No results found"));
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final noteId = result.$1;
                        final title = result.$2;
                        final content = result.$3;
                        final folderName = result.$5;
                        
                        return ListTile(
                          leading: const Icon(Icons.note),
                          title: Text(title),
                          subtitle: Text(
                            "$folderName • ${content.length > 50 ? content.substring(0, 50) + '...' : content}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close search dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteDetailScreen(
                                  noteId: noteId,
                                  initialTitle: title,
                                  initialContent: content,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider
    final engine = context.watch<EngineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("TactaNotes"),
            const Spacer(),
            if (engine.userName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    engine.userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearchDialog),
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
                : engine.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No notes yet",
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Create Note"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NoteDetailScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: engine.notes.length,
                        itemBuilder: (context, index) {
                          final note = engine.notes[index];
                          // Note tuple: (id, title, content, updated)
                          final id = note.$1;
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailScreen(
                                    noteId: id,
                                    initialTitle: title,
                                    initialContent: content,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: engine.currentFolderId != null ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // New Note FAB
          FloatingActionButton(
            heroTag: 'new_note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoteDetailScreen(),
                ),
              );
            },
            child: const Icon(Icons.note_add),
          ),
          const SizedBox(height: 16),
          // Record FAB
          FloatingActionButton(
            key: const ValueKey('record_button'),
            heroTag: 'record',
            onPressed: () {
              // Pass current folder name as subject for now
              final folderName = engine.folders.firstWhere((f) => f.$1 == engine.currentFolderId).$2;
              Navigator.push(context, MaterialPageRoute(builder: (_) => RecordingScreen(subject: folderName)));
            },
            child: const Icon(Icons.mic),
          ),
        ],
      ) : null,
    );
  }
}
