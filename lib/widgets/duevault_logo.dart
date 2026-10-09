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
    final radius = BorderRadius.circular(size * 0.25);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  blurRadius: size * 0.25,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/app icon.png',
          width: size,
          height: size,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: const Color(0xFF10B981),
            alignment: Alignment.center,
            child: Icon(
              Icons.shield_rounded,
              size: size * 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

