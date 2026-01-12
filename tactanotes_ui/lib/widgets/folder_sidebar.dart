import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/engine_provider.dart';

class FolderSidebar extends StatefulWidget {
  const FolderSidebar({super.key});

  @override
  State<FolderSidebar> createState() => _FolderSidebarState();
}

class _FolderSidebarState extends State<FolderSidebar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngineProvider>().loadFolders();
    });
  }

  void _showNewFolderDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Folder Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                final newId = await context.read<EngineProvider>().createFolder(_controller.text);
                if (context.mounted && newId != null) {
                    context.read<EngineProvider>().selectFolder(newId);
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineProvider>();
    
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Folders", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: _showNewFolderDialog,
                  tooltip: "New Folder",
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: engine.folders.length,
              itemBuilder: (context, index) {
                final folder = engine.folders[index];
                // folder is Record (int, String)
                final id = folder.$1;
                final name = folder.$2;
                final isSelected = engine.currentFolderId == id;
                
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.folder : Icons.folder_outlined,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(name),
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () => engine.selectFolder(id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
