import 'dart:ui';
import 'package:flutter/material.dart';

class ButtonWithIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;
  final Color iconColor;
  final bool isSelected;

  const ButtonWithIcon({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ButtonWithIconSate();
}

class ButtonWithIconSate extends State<ButtonWithIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    bool isBlur = widget.backgroundColor == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: Duration(milliseconds: 150),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
          ),
          child: isBlur
              ? _buildBlurButton()
              : _buildSolidButton(),
        ),
      ),
    );
  }

  Widget _buildBlurButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: widget.iconColor,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolidButton() {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: widget.iconColor,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

