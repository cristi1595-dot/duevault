import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault AppShimmer Component
/// Reusable skeleton animation for progressive loading states across cards, lists, and forms.
class AppShimmer extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const AppShimmer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = AppRadius.md,
    this.shape,
  });

  /// Factory for a rectangular / rounded block
  const factory AppShimmer.box({
    Key? key,
    required double width,
    required double height,
    double borderRadius,
  }) = _AppShimmerBox;

  /// Factory for a circular skeleton (e.g. avatar, icon placeholder)
  const factory AppShimmer.circle({
    Key? key,
    required double size,
  }) = _AppShimmerCircle;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.slate800
        : AppColors.slate200;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = baseColor.withValues(alpha: _animation.value);

        if (widget.child != null) {
          return Opacity(
            opacity: _animation.value,
            child: widget.child,
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: widget.shape != null
              ? ShapeDecoration(color: color, shape: widget.shape!)
              : BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
        );
      },
    );
  }
}

class _AppShimmerBox extends AppShimmer {
  const _AppShimmerBox({
    super.key,
    required double width,
    required double height,
    super.borderRadius = AppRadius.md,
  }) : super(
          width: width,
          height: height,
        );
}

class _AppShimmerCircle extends AppShimmer {
  const _AppShimmerCircle({
    super.key,
    required double size,
  }) : super(
          width: size,
          height: size,
          shape: const CircleBorder(),
        );
}
