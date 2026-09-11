import 'package:flutter/material.dart';

class PagePlacement extends StatelessWidget {
  const PagePlacement({
    super.key,
    required this.child,
    required this.relative,
    required this.onChanged,
  });

  final Widget child;
  final Offset relative;
  final ValueChanged<Offset> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          onTapDown: (d) => onChanged(Offset(d.localPosition.dx / w, d.localPosition.dy / h)),
          onPanUpdate: (d) =>
              onChanged(Offset(d.localPosition.dx / w, d.localPosition.dy / h)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9D2CB)),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _PageLinesPainter()),
                ),
                Align(
                  alignment: Alignment(relative.dx * 2 - 1, relative.dy * 2 - 1),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9E3DC)
      ..strokeWidth = 1;
    for (var y = 18.0; y < size.height - 10; y += 14) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
