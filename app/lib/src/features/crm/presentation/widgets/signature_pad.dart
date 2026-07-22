import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final ValueChanged<List<Offset>> onSign;
  final VoidCallback onClear;

  const SignaturePad({
    super.key,
    required this.onSign,
    required this.onClear,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset?> _points = [];

  void _addPoint(PointerEvent details) {
    RenderBox referenceBox = context.findRenderObject() as RenderBox;
    Offset localPosition = referenceBox.globalToLocal(details.position);
    setState(() {
      _points = List.from(_points)..add(localPosition);
    });
    // Send non-null points back
    widget.onSign(_points.whereType<Offset>().toList());
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Listener(
            onPointerDown: _addPoint,
            onPointerMove: _addPoint,
            onPointerUp: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: CustomPaint(
              painter: _SignaturePainter(points: _points),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Signature'),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
