import 'package:flutter/material.dart';
import 'package:maromart/Colors/AppColors.dart';

class ModernLoader extends StatefulWidget {
  final Color? color;
  final double size;

  const ModernLoader({super.key, this.color, this.size = 60.0}); // Reduced default size

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Image.asset(
              'assets/images/cute_robot.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image missing
                return Icon(Icons.smart_toy, size: widget.size, color: AppColors.primary);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Vui lòng chờ chút nhé...",
          style: TextStyle(
            fontFamily: 'QuickSand',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
