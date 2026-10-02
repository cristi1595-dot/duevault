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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark
        ? const Color(0xFF161A22).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? const Color(0xFF222734)
        : const Color(0xFFE2E8F0);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tab 0: Home
                  Expanded(
                    child: _buildNavItem(
                      0,
                      Icons.home_rounded,
                      'Home',
                      inactiveColor,
                      primaryColor,
                    ),
                  ),
                  // Tab 1: Bills
                  Expanded(
                    child: _buildNavItem(
                      1,
                      Icons.receipt_long_rounded,
                      'Bills',
                      inactiveColor,
                      primaryColor,
                    ),
                  ),
                  // Center (+) Add Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PulsingAddButton(
                      onPressed: onAddPressed,
                      shouldPulse: isVaultEmpty,
                    ),
                  ),
                  // Tab 2: Documents
                  Expanded(
                    child: _buildNavItem(
                      2,
                      Icons.description_rounded,
                      'Documents',
                      inactiveColor,
                      primaryColor,
                    ),
                  ),
                  // Tab 3: Settings
                  Expanded(
                    child: _buildNavItem(
                      3,
                      Icons.tune_rounded,
                      'Settings',
                      inactiveColor,
                      primaryColor,
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
    Color activeColor,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor.withValues(alpha: 0.65);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isSelected ? 1.08 : 1.0,
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isSelected ? 12 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(
                      alpha: widget.shouldPulse ? 0.45 : 0.25,
                    ),
                    blurRadius: glow,
                    spreadRadius: spread,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


