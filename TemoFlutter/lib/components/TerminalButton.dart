import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final double height;

  const TerminalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor = const Color(0xFF00FF41), // Classic Terminal Green
    this.height = 56,
  });

  @override
  State<TerminalButton> createState() => _TerminalButtonState();
}

class _TerminalButtonState extends State<TerminalButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
              if (_isPressed)
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              Text(
                ">",
                style: GoogleFonts.shareTechMono(
                  color: widget.accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                widget.icon,
                color: widget.accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: widget.accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              FadeTransition(
                opacity: _blinkController,
                child: Container(
                  width: 10,
                  height: 20,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
