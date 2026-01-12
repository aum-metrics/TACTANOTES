import 'package:flutter/material.dart';
import 'recording_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // F8: Academic Hierarchy (Mocked list)
    final subjects = ["Physics 101", "Calculus II", "History of Art"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}), // F16 Zen UI
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        key: const ValueKey('subjects_list'),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.folder, color: Colors.blueGrey),
            title: Text(subjects[index]),
            subtitle: Text("${index + 2} Lectures"),
            onTap: () {
              // Navigate to Subject Detail
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('record_button'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordingScreen()));
        },
        child: const Icon(Icons.mic), // Centered action (F16)
      ),
    );
  }
}
