import 'dart:ui';
import 'package:flutter/material.dart';

class IntegratedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;
  final bool isVaultEmpty;

  const IntegratedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
    required this.isVaultEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65), // Dark semi-transparent background
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildNavItem(
                      0,
                      Icons.home_rounded,
                      'Home',
                      inactiveColor,
                    ),
                  ),
                  PulsingAddButton(
                    onPressed: onAddPressed,
                    shouldPulse: isVaultEmpty,
                  ),
                  Expanded(
                    child: _buildNavItem(
                      1,
                      Icons.folder_rounded,
                      'Vault',
                      inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color inactiveColor,
  ) {
    final isSelected = currentIndex == index;
    const activeColor = Colors.greenAccent;
    final color = isSelected ? activeColor : inactiveColor.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isSelected ? 16 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool shouldPulse;

  const PulsingAddButton({
    super.key,
    required this.onPressed,
    required this.shouldPulse,
  });

  @override
  State<PulsingAddButton> createState() => _PulsingAddButtonState();
}

class _PulsingAddButtonState extends State<PulsingAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 12.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingAddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse != oldWidget.shouldPulse) {
      if (widget.shouldPulse) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.shouldPulse ? _scaleAnimation.value : 1.0;
        final glow = widget.shouldPulse ? _glowAnimation.value : 12.0;
        final spread = widget.shouldPulse ? 2.0 + (_controller.value * 2.0) : 2.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Colors.greenAccent,
                    Color(0xFF00E676),
                  ],
                  center: Alignment.center,
                  radius: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(
                      alpha: widget.shouldPulse ? 0.35 + (_controller.value * 0.15) : 0.35,
                    ),
                    blurRadius: glow,
                    spreadRadius: spread,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}


