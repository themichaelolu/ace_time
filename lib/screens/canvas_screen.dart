import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final points = <Offset>[];
  Color selected = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collaborative Canvas')),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() => points.add(details.localPosition));
        },
        child: CustomPaint(
          painter: CanvasPainter(points, selected),
          child: Container(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Pick Color"),
            content: BlockPicker(
              pickerColor: selected,
              onColorChanged: (c) => setState(() => selected = c),
            ),
          ),
        ),
        child: const Icon(Icons.color_lens),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  CanvasPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(CanvasPainter old) => true;
}
