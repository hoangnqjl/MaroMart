import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';

class ModernLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final bool showText;

  const ModernLoader({super.key, this.color, this.size = 60.0, this.showText = true});

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
    return Center(
      child: Column(
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
                  return Icon(Icons.smart_toy, size: widget.size, color: AppColors.primary);
                },
              ),
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                "Vui lòng chờ chút nhé...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'QuickSand',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.color ?? Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
