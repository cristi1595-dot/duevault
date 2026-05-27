import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_theme.dart';

class FinancialBentoCard extends ConsumerWidget {
  const FinancialBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    // Calculate Stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final expiredDocs = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final upcomingBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDueOverdue = overdueBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final totalDue7Days =
        (upcomingBills.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

    final items30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.isArchived || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDue30Days =
        (items30Days.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

    // Calculate Document Expirations
    final expiredDocs7Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final expiredDocs30Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    // Check urgency states
    final totalDocs7Days = expiredDocs.length + expiredDocs7Days.length;
    final totalDocs30Days = expiredDocs.length + expiredDocs30Days.length;

    // Calculate days remaining across active unpaid items to determine status
    final activeItems = vaultItems.where((item) {
      if (item.dueDate == null) return false;
      if (item.itemType == 'Bill') {
        return !item.isPaid;
      } else if (item.itemType == 'Document') {
        return !item.isArchived && !item.isPaid;
      }
      return false;
    }).toList();

    int minDaysLeft = 99999;
    for (final item in activeItems) {
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      final days = due.difference(today).inDays;
      if (days < minDaysLeft) {
        minDaysLeft = days;
      }
    }

    final hasOverdueOrExpired = overdueBills.isNotEmpty || expiredDocs.isNotEmpty;

    // Boundary logic:
    // Red (Urgent): 3 days or fewer (minDaysLeft <= 3), or has overdue/expired items.
    // Yellow (Warning): 7 days or fewer (minDaysLeft <= 7), and no Red items.
    // Green (Safe): over 7 days (minDaysLeft > 7), or no items due.
    final bool isUrgentRed = hasOverdueOrExpired || minDaysLeft <= 3;
    final bool isWarningYellow = !isUrgentRed && minDaysLeft <= 7;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isUrgentRed) {
      statusColor = AppTheme.urgentRed;
      statusLabel = 'ACTION REQUIRED';
      statusIcon = Icons.error_outline_rounded;
    } else if (isWarningYellow) {
      statusColor = AppTheme.warningYellow;
      statusLabel = 'UPCOMING DUE';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.safeGreen;
      statusLabel = 'ALL CLEAR';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    // Premium dynamic background tinting
    final Color baseStartColor = isDark ? const Color(0xFF1C2028) : Colors.white;
    final Color baseEndColor = isDark ? const Color(0xFF101217) : const Color(0xFFF8FAFC);

    final double blendStartOpacity = isDark ? 0.08 : 0.05;
    final double blendEndOpacity = isDark ? 0.02 : 0.02;

    final Color startColor = Color.alphaBlend(
      statusColor.withValues(alpha: blendStartOpacity),
      baseStartColor,
    );
    final Color endColor = Color.alphaBlend(
      statusColor.withValues(alpha: blendEndOpacity),
      baseEndColor,
    );

    final cardGradient = LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final double borderOpacity = isDark ? 0.15 : 0.22;
    final double shadowOpacity = isDark ? 0.04 : 0.06;
    final Color borderColor = statusColor.withValues(alpha: borderOpacity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: shadowOpacity),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Status & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '7-DAY OUTLOOK',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 13.2,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Hero bills amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currency.formatAmount(totalDue7Days),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 37.4,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'due bills',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    fontSize: 15.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (totalDueOverdue > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15.6,
                    color: AppTheme.urgentRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Includes ${currency.formatAmount(totalDueOverdue)} overdue',
                    style: const TextStyle(
                      color: AppTheme.urgentRed,
                      fontSize: 14.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 3),

            // Subtle document status row
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 15.6,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                const SizedBox(width: 5),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 14.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: totalDocs7Days == 1
                            ? '1 document expiring soon'
                            : '$totalDocs7Days documents expiring soon',
                      ),
                      if (expiredDocs.isNotEmpty) ...[
                        const TextSpan(text: ' ('),
                        TextSpan(
                          text: expiredDocs.length == 1
                              ? '1 expired'
                              : '${expiredDocs.length} expired',
                          style: const TextStyle(
                            color: AppTheme.urgentRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ')'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                height: 1,
              ),
            ),

            // Row 4: 30-Day Forecast Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 15.6,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '30-DAY FORECAST',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Bills: ',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontSize: 14.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currency.formatAmount(totalDue30Days),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF090D16),
                        fontSize: 15.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.description_outlined,
                      size: 14.4,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalDocs30Days',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF090D16),
                        fontSize: 15.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
