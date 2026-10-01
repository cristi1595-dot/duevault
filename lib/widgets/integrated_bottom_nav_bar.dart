import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? const Color(0xFF8E99A8) : const Color(0xFF64748B);
    const activeColor = AppTheme.primaryAction;

    final barBg = isDark
        ? const Color(0xFF12151C).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.90);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tab 0: Home / Acasă
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'Acasă',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ),
                  // Tab 1: Bills / Facturi
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      index: 1,
                      icon: Icons.receipt_long_rounded,
                      label: 'Facturi',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ),
                  // Center Button: Quick Add (+)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PulsingAddButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onAddPressed();
                      },
                      shouldPulse: isVaultEmpty,
                    ),
                  ),
                  // Tab 2: Docs / Documente
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      index: 2,
                      icon: Icons.folder_shared_rounded,
                      label: 'Documente',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ),
                  // Tab 3: Settings / Hub
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      index: 3,
                      icon: Icons.tune_rounded,
                      label: 'Setări',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
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

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
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
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 18.0).animate(
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
        final glow = widget.shouldPulse ? _glowAnimation.value : 8.0;

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
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: widget.shouldPulse ? 0.6 : 0.35),
                    blurRadius: glow,
                    offset: const Offset(0, 3),
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
