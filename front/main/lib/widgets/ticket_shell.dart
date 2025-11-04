import 'package:flutter/material.dart';

/// 공용 열차표 형태의 카드 레이아웃
class TicketShell extends StatelessWidget {
  final Widget upperSection;
  final Widget lowerSection;
  final Gradient gradient;
  final Color accentColor;
  final EdgeInsetsGeometry contentPadding;
  final double notchPosition;

  const TicketShell({
    super.key,
    required this.upperSection,
    required this.lowerSection,
    required this.gradient,
    required this.accentColor,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.notchPosition = 0.52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _TicketClipper(notchPosition: notchPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: contentPadding,
                child: upperSection,
              ),
              SizedBox(
                width: double.infinity,
                height: 16,
                child: CustomPaint(
                  painter: _DashedLinePainter(color: accentColor.withOpacity(0.5)),
                ),
              ),
              Padding(
                padding: contentPadding,
                child: lowerSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double borderRadius;
  final double notchPosition;

  _TicketClipper({
    this.notchRadius = 18,
    this.borderRadius = 24,
    this.notchPosition = 0.5,
  });

  @override
  Path getClip(Size size) {
    final notchCenterY = size.height * notchPosition;
    final path = Path();

    path.moveTo(borderRadius, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, notchCenterY - notchRadius);
    path.arcToPoint(
      Offset(size.width, notchCenterY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(size.width, size.height, size.width - borderRadius, size.height);
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, notchCenterY + notchRadius);
    path.arcToPoint(
      Offset(0, notchCenterY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) {
    return notchRadius != oldClipper.notchRadius ||
        borderRadius != oldClipper.borderRadius ||
        notchPosition != oldClipper.notchPosition;
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    this.dashWidth = 8,
    this.dashSpace = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return color != oldDelegate.color ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace;
  }
}
