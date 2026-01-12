import 'package:flutter/material.dart';

// Feature F9: Non-Destructive Annotation Layer
// Architecture:
// Stack {
//   1. Content Layer (Image/PDF Stub)
//   2. Ink Layer (CustomPainter)
// }

class AnnotationCanvas extends StatefulWidget {
  final Widget content; // The background content (Image, PDF Tile, etc.)

  const AnnotationCanvas({super.key, required this.content});

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  // Vector stroage for strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. content Layer
        Positioned.fill(
          child: widget.content,
        ),
        
        // 2. Ink Layer
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _strokes.add(List.from(_currentStroke));
                _currentStroke = [];
              });
            },
            child: CustomPaint(
              painter: _InkPainter(_strokes, _currentStroke),
              size: Size.infinite,
            ),
          ),
        ),
        
        // Controls (Undo/Clear)
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            children: [
              FloatingActionButton.small(
                heroTag: "undo",
                child: const Icon(Icons.undo), 
                onPressed: () => setState(() { if(_strokes.isNotEmpty) _strokes.removeLast(); })
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: "clear",
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.delete), 
                onPressed: () => setState(() { _strokes.clear(); })
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _InkPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.6) // Highlighter style
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path()..addPolygon(stroke, false);
        canvas.drawPath(path, paint);
      }
    }

    if (currentStroke.length > 1) {
      final path = Path()..addPolygon(currentStroke, false);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
