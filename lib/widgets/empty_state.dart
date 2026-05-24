import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing neon icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryAction.withValues(alpha: isDark ? 0.03 : 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryAction.withValues(alpha: isDark ? 0.15 : 0.3),
                  width: 1.5,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryAction.withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppTheme.primaryAction,
              ),
            ),
            const SizedBox(height: 28),
            // Headline
            Text(
              'Your vault is empty',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Subtitle (gray)
            Text(
              'Tap + to add your first document or bill.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13.5,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
