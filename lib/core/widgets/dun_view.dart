import 'package:flutter/material.dart';

enum DunState { resting, focused, celebrating }

class DunView extends StatelessWidget {
  const DunView({this.state = DunState.resting, super.key});
  final DunState state;
  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (state) {
      DunState.resting => 'Dun is resting',
      DunState.focused => 'Dun is focused',
      DunState.celebrating => 'Dun is celebrating',
    },
    child: Transform.scale(
      scale: state == DunState.focused ? 1.05 : 1,
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _DunPainter(
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.onSurface,
          state,
        ),
      ),
    ),
  );
}

class _DunPainter extends CustomPainter {
  const _DunPainter(this.color, this.ink, this.state);
  final Color color, ink;
  final DunState state;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 48, Paint()..color = color);
    final eye = Paint()..color = ink;
    canvas.drawCircle(center.translate(-16, -6), 4, eye);
    canvas.drawCircle(center.translate(16, -6), 4, eye);
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, 2), radius: 18),
      0.2,
      state == DunState.celebrating ? 2.7 : 2.3,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _DunPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.state != state;
}
