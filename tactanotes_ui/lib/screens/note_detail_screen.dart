import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/engine_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/drawing_canvas.dart';

class NoteDetailScreen extends StatefulWidget {
  final int? noteId; // null = new note
  final String? initialTitle;
  final String? initialContent;

  const NoteDetailScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Phase 3: Media & Attachments
  List<(int, String, String)> _attachments = [];
  bool _isRecording = false;
  String _recordingTranscript = "";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _isEditing = widget.noteId == null; // New notes start in edit mode
    
    if (widget.noteId != null) {
      _loadAttachments();
    }
  }

  Future<void> _loadAttachments() async {
    final engine = context.read<EngineProvider>();
    final attachments = await engine.getAttachments(widget.noteId!);
    setState(() {
      _attachments = attachments;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final engine = context.read<EngineProvider>();
    bool success;

    if (widget.noteId == null) {
      // Create new note
      success = await engine.createNote(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
    } else {
      // Update existing note
      success = await engine.updateNote(
        widget.noteId!,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
        setState(() => _isEditing = false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note')),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.noteId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final engine = context.read<EngineProvider>();
      final success = await engine.deleteNote(widget.noteId!);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Go back to home screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete note')),
          );
        }
      }
    }
  }

  // --- Phase 3 Actions ---

  Future<void> _pickFile() async {
    if (widget.noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the note first')));
      return;
    }
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx', 'xls', 'xlsx', 'docx', 'txt'],
    );

    if (result != null) {
      final file = result.files.first;
      if (file.path != null) {
        final engine = context.read<EngineProvider>();
        await engine.addAttachment(widget.noteId!, file.extension ?? 'file', file.path!);
        _loadAttachments();
      }
    }
  }

  Future<void> _pickImage() async {
    if (widget.noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the note first')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final engine = context.read<EngineProvider>();
      await engine.addAttachment(widget.noteId!, 'image', image.path);
      _loadAttachments();
    }
  }

  Future<void> _takePhoto() async {
    if (widget.noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the note first')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final engine = context.read<EngineProvider>();
      await engine.addAttachment(widget.noteId!, 'image', photo.path);
      _loadAttachments();
    }
  }

  void _toggleRecording() async {
    if (widget.noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the note first')));
      return;
    }

    final engine = context.read<EngineProvider>();
    
    if (_isRecording) {
      setState(() => _isRecording = false);
      await engine.stop(appendToNoteId: widget.noteId);
      final note = await engine.getNote(widget.noteId!);
      if (note != null) {
        setState(() {
          _contentController.text = note.$3;
        });
      }
    } else {
      setState(() {
        _isRecording = true;
        _recordingTranscript = "";
      });
      await engine.startRecording(_titleController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New Note' : 'Note Details'),
        actions: [
          // Always show save when editing (for new notes or when edit mode is active)
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Save'),
                      onPressed: _saveNote,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
          // Show edit button only for existing notes in view mode
          if (!_isEditing && widget.noteId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit'),
                onPressed: () => setState(() => _isEditing = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          // Show delete button only for existing notes
          if (widget.noteId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.delete, size: 24),
                tooltip: 'Delete Note',
                color: Colors.red[300],
                onPressed: _deleteNote,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              enabled: _isEditing,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Note Title',
                border: _isEditing ? const UnderlineInputBorder() : InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            
            // Content Field
            Expanded(
              child: TextField(
                controller: _contentController,
                enabled: _isEditing,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Start typing your note...',
                  border: _isEditing 
                    ? const OutlineInputBorder()
                    : InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            
            // Attachments List (Horizontal scroll)
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final att = _attachments[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            att.$2 == 'image' ? Icons.image : Icons.insert_drive_file,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            att.$3.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),
            
            // Action Bar (Phase 3) - Always visible
            if (true) // Removed _isEditing guard for seamless access
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.blue,
                      label: _isRecording ? 'Stop' : 'Record',
                      onTap: _toggleRecording,
                    ),
                    _ActionButton(
                      icon: Icons.attach_file,
                      label: 'File',
                      onTap: _pickFile,
                    ),
                    _ActionButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _takePhoto,
                    ),
                    _ActionButton(
                      icon: Icons.brush,
                      label: 'Draw',
                      onTap: () {
                        if (widget.noteId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the note first')));
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrawingCanvas(
                              onSave: (path) async {
                                final engine = context.read<EngineProvider>();
                                await engine.addAttachment(widget.noteId!, 'image', path);
                                _loadAttachments();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // Metadata (if viewing existing note)
            if (widget.noteId != null && !_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Last updated: ${DateTime.now().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
