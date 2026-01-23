import 'package:flutter/material.dart';
import 'package:maromart/components/ModernLoader.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String fullName;
  final double size;
  final double fontSize;

  const UserAvatar({
    Key? key,
    required this.avatarUrl,
    required this.fullName,
    this.size = 50,
    this.fontSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildAvatar(),
      ),
    );
  }

  Widget _buildAvatar() {
    if (avatarUrl.isEmpty) {
      return _buildLetterAvatar();
    }

    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildLetterAvatar();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: ModernLoader(size: size * 0.4),
        );
      },
    );
  }

  Widget _buildLetterAvatar() {
    String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    return Container(
      color: _getColorFromName(fullName),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.blueAccent;

    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
    ];

    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash += name.codeUnitAt(i);
    }

    return colors[hash % colors.length];
  }
}