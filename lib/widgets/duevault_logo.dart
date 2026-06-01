import 'package:flutter/material.dart';

class DueVaultLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const DueVaultLogo({
    super.key,
    this.size = 100,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  blurRadius: size * 0.3,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/app icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

