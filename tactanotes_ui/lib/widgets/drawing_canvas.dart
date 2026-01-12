import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DrawingCanvas extends StatefulWidget {
  final Function(String path) onSave;

  const DrawingCanvas({super.key, required this.onSave});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<void> _saveDrawing() async {
    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(data);
      widget.onSave(path);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sketch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _controller.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Signature(
          controller: _controller,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
