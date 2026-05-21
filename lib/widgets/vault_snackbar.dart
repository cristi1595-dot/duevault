import 'package:flutter/material.dart';
import '../main.dart';

class VaultSnackBar {
  static void show({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Color? backgroundColor,
    Duration? duration,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    messenger?.removeCurrentSnackBar();

    final snckDuration = duration ?? const Duration(milliseconds: 3000);

    final controller = messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: snckDuration,
        backgroundColor: backgroundColor ?? const Color(0xFF2D2D2D),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.2),
              )
            : null,
      ),
    );

    // Manual safety trigger: forcefully close the snackbar after the duration
    // in case the OS accessibility or kernel blocks the automatic dismissal.
    Future.delayed(snckDuration + const Duration(milliseconds: 100), () {
      try {
        controller?.close();
      } catch (_) {
        // Already closed, ignore
      }
    });
  }
}
