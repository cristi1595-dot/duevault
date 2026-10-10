import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';

class FinancialBentoCard extends ConsumerWidget {
  const FinancialBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

    // --- BILLS STATS ---
    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final overdueBillsTotal = overdueBills.fold<double>(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final upcomingBills7Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalBills7Days = (upcomingBills7Days.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount ?? 0),
        )) +
        overdueBillsTotal;

    final upcomingBills30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalBills30Days = (upcomingBills30Days.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount ?? 0),
        )) +
        overdueBillsTotal;

    // --- DOCUMENTS STATS ---
    final expiredDocs = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final upcomingDocs7Days = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDocs7Days = expiredDocs.length + upcomingDocs7Days.length;

    final upcomingDocs30Days = vaultItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDocs30Days = expiredDocs.length + upcomingDocs30Days.length;

    // Design Tokens & Styling
    final cardBg = AppColors.surface(isDark);
    final borderColor = AppColors.border(isDark);
    final billAccent = isDark ? AppColors.emerald400 : AppColors.emerald600;
    final docAccent = isDark ? AppColors.infoBlue400 : AppColors.infoBlue700;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === LEFT COLUMN: BILLS ===
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('bento_bills_column'),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.xl),
                    ),
                    splashColor: AppColors.emerald500.withValues(alpha: 0.08),
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.emerald500.withValues(alpha: isDark ? 0.04 : 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 30 Days VEDETA Metric (Big & Bold on top)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NEXT 30 DAYS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: billAccent,
                                ),
                              ),
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 14,
                                color: billAccent.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${currency.symbol}${totalBills30Days.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    fontSize: 23,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                            ),
                          ),

                          // Overdue indicator if any
                          if (overdueBills.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusUrgentText(isDark).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                border: Border.all(
                                  color: AppColors.statusUrgentText(isDark).withValues(alpha: 0.25),
                                  width: 0.75,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 11,
                                    color: AppColors.statusUrgentText(isDark),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${overdueBills.length} overdue',
                                    style: TextStyle(
                                      color: AppColors.statusUrgentText(isDark),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.md),

                          // 7 Days Secondary Metric
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 1,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated(isDark),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.border(isDark)
                                    : AppColors.slate200,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary(isDark),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '7 Days',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${currency.symbol}${totalBills7Days.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary(isDark),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Vertical Divider between Columns
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
              ),

              // === RIGHT COLUMN: DOCUMENTS ===
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('bento_docs_column'),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.xl),
                    ),
                    splashColor: AppColors.infoBlue500.withValues(alpha: 0.08),
                    onTap: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 2;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.infoBlue500.withValues(alpha: isDark ? 0.04 : 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 30 Days VEDETA Metric (Big & Bold on top)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NEXT 30 DAYS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: docAccent,
                                ),
                              ),
                              Icon(
                                Icons.folder_open_rounded,
                                size: 14,
                                color: docAccent.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$totalDocs30Days',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        fontSize: 23,
                                        color: AppColors.textPrimary(isDark),
                                      ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'expiring',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Expired indicator if any
                          if (expiredDocs.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusUrgentText(isDark).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                border: Border.all(
                                  color: AppColors.statusUrgentText(isDark).withValues(alpha: 0.25),
                                  width: 0.75,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 11,
                                    color: AppColors.statusUrgentText(isDark),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${expiredDocs.length} expired',
                                    style: TextStyle(
                                      color: AppColors.statusUrgentText(isDark),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.md),

                          // 7 Days Secondary Metric
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 1,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated(isDark),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.border(isDark)
                                    : AppColors.slate200,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary(isDark),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '7 Days',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '$totalDocs7Days expiring',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary(isDark),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
