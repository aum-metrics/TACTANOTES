import 'package:flutter/material.dart';

// Feature v5.1: PDF Tiling (Memory Safe)
// MANDATE: Never load entire PDF into RAM.
// Use 'pdf_render' or platform channel to render bitmap tiles.
// Keep only visible tiles + 1 page buffer in memory.

class PdfViewerStub extends StatelessWidget {
  final String path;

  const PdfViewerStub({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "PDF Tiling Engine",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Rendering: $path",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Architecture Note:\n"
                  "1. Native Bitmap Rendering (Android/iOS)\n"
                  "2. Tile Caching (LRU Strategy)\n"
                  "3. Zoom-dependent resolution\n"
                  "4. Max RAM: ~50MB per page view",
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
