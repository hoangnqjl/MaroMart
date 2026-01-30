import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:maromart/Colors/AppColors.dart';

class ModernLoader extends StatefulWidget {
  final Color? color;
  final double size;

  const ModernLoader({super.key, this.color, this.size = 50.0});

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return CustomPaint(
            painter: _LoaderPainter(
              color: widget.color ?? AppColors.primary, // Default to primary color
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _LoaderPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill; // changed to fill for dots
      
    // Option: 3 Orbiting dots
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2;
    final double dotRadius = radius / 4;
    
    // We create 3 dots rotating
    for (int i = 0; i < 3; i++) {
        // Offset phases
        final double phase = (i * 2 * math.pi) / 3; 
        final double currentAngle = (animationValue * 2 * math.pi) + phase;
        
        // Calculate position
        final double dx = cx + (radius - dotRadius) * math.cos(currentAngle);
        final double dy = cy + (radius - dotRadius) * math.sin(currentAngle);
        
        // Dynamic Opacity for "Tail" effect logic or pulsing
        // Simply solid rotating dots for now, looks clean.
        // Let's add scale pulsing: when at bottom, smaller? No, keep it simple specific.
        
        canvas.drawCircle(Offset(dx, dy), dotRadius, paint);
    }
    
    // Center glow (Optional)
    // canvas.drawCircle(Offset(cx, cy), dotRadius / 2, paint..color = color.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
